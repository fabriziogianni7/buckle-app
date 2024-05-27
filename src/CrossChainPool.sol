// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// import {console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CCIPReceiver} from "ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "ccip/contracts/libraries/Client.sol";
import {IRouterClient} from "ccip/contracts/interfaces/IRouterClient.sol";

/**
 * @notice
 * This contract is deployed in pair with the same token on another chain
 * eg.
 *     I deploy CrossChainPoolWETH on Base and deploy CrossChainPoolWETH on Arbitrum
 *     those 2 contracts will be able to exchange liquidity crosschain
 * @custom:functionalities
 *  Users can "teleport" tokens to the other networks
 *  LPs can deposit underlying and get LPTs in exchange
 *  LPs can withdraw underlying and burn LPTS
 * @custom:roles
 *  there are 2 roles:
 *     users: the ones that use this contracts as a bridge aka teleport
 *     LPs: users which put liquidity on the pools
 * @custom:invariant
 *  we want the ratio between underlying tokens and LPTs always >= 1 ---> Underlying / LPT >= 1
 * uderlying
 *  value of 1 LPT should always be equal or or less than the value of underlying token
 * DO NOT USE THIS CONTRACT IN MAINNET as it's not audited and still in beta version
 */
contract CrossChainPool is ERC20, ReentrancyGuard, CCIPReceiver, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error CrossChainPool__ShouldBeMoreThanZero();
    error CrossChainPool__WrongUnderlying();
    error CrossChainPool__NotLP();
    error CrossChainPool__SenderOrSelectorNotAllowed();
    error CrossChainPool__UserCCipFeesNotEnough();
    error CrossChainPool__NotEnoughBalanceOnDestinationPool();
    error CrossChainPool__AmountTooSmall();
    error CrossChainPool__NotEnoughBalanceToRedeem();
    error CrossChainPool__NotEnoughBalanceToRedeemCrossChain();
    error CrossChainPool__NotEnoughBalanceToRedeemCurrentChain();
    error CrossChainPool__CooldownNotExpired();
    error CrossChainPool__CooldownAmountTooHigh();

    /*//////////////////////////////////////////////////////////////
                            TYPES DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IERC20 private immutable i_underlyingToken;
    uint64 private immutable i_crossChainSelector;
    uint8 private constant TELEPORT_FUNCTION_ID = 1;
    uint8 private constant DEPOSIT_FUNCTION_ID = 2;
    uint8 private constant REDEEM_FUNCTION_ID = 3;
    uint8 private constant COOLDOWN_FUNCTION_ID = 4;
    // sum of storage space 32 bytes

    IERC20 private immutable i_otherChainUnderlyingToken;
    uint16 private s_fee_bps = 500;
    uint24 private s_gas_limit = 100_000;
    uint24 private s_cooldownPeriod = 6 hours;
    // sum of storage space 28 bytes

    address private s_crossChainPool; // the address of the other chain linked to this one

    bytes32 private s_lastSentMessageId;

    bytes32 private s_lastReceivedMessageId;

    uint256 private s_crossChainUnderlyingBalance;

    uint256 private s_crossChainLiquidityPoolTokens;

    mapping(address => uint256) private readyToWithdraw;
    mapping(address => uint256) private s_cooldownAmount;
    mapping(address => uint256) private s_cooldown;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event DepositedAndMintedLpt(
        address indexed lp,
        uint256 indexed lptAmount,
        address indexed underlyingToken,
        uint256 underlyingAmount,
        uint256 chainid
    );

    event Redeem(address indexed lp, uint256 indexed underlyingAmount, uint256 indexed chainid);

    event Teleport(
        uint256 indexed teleportedAmount, address indexed to, address indexed underlyingToken, uint64 crosschainSelector
    );

    event MessageReceived(bytes32 indexed messageId);

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice check if crosschainsender and cross chain are allowed to send messages here
     */
    modifier areSenderAndSelectorAllowed(bytes memory _sender, uint64 _selector) {
        address decodedSender = _bytesToAddress(_sender);
        (address allowedSender, uint64 allowedSelector) = getCrossChainSenderAndSelector();

        if (allowedSender != decodedSender || allowedSelector != _selector) {
            revert CrossChainPool__SenderOrSelectorNotAllowed();
        }
        _;
    }

    /**
     * @notice if amount is <= 0 revert
     */
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert CrossChainPool__ShouldBeMoreThanZero();
        }
        _;
    }

    /**
     * @notice check if the token being deposited is correct
     */
    modifier isCorrectToken(IERC20 token) {
        if (token != i_underlyingToken) {
            revert CrossChainPool__WrongUnderlying();
        }
        _;
    }

    /**
     * @notice check if user is a lp
     */
    modifier isUserLiquidityProvider() {
        if (balanceOf(msg.sender) <= 0) {
            revert CrossChainPool__NotLP();
        }
        _;
    }

    /**
     * @notice check if cooldown period is passed
     */
    modifier isCooldownPeriodExpired() {
        if (!_isCooldownExpired(msg.sender)) {
            revert CrossChainPool__CooldownNotExpired();
        }
        _;
    }

    /**
     * @notice check the amount being redeemed is
     */
    modifier isLPRedeemingCorrectAmount(uint256 _amount) {
        if (s_cooldownAmount[msg.sender] > _amount) {
            revert CrossChainPool__CooldownAmountTooHigh();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice creates the pool
     * @param _underlyingToken is the ERC20 that gets teleported
     * @param _name is the name of this pool
     * @param _crossChainSelector is the corresponding pool selector on the other network
     * @param _router the router of the current network
     * @param _otherChainUnderlyingToken the other token of the pair
     */
    constructor(
        address _underlyingToken,
        string memory _name,
        uint64 _crossChainSelector,
        address _router,
        address _otherChainUnderlyingToken
    ) ERC20(string.concat("BUCKLE", _name), string.concat("BCK", _name)) CCIPReceiver(_router) Ownable(msg.sender) {
        i_underlyingToken = IERC20(_underlyingToken);
        i_otherChainUnderlyingToken = IERC20(_otherChainUnderlyingToken);
        i_crossChainSelector = _crossChainSelector;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice set cooldown period for the LP
     * LPs need to wait at least 6 hours before redeeming their tokens
     * when a cooldown is set this function send a message crosschain to update the balances of the pool pair
     *  subtracts the redeemCrossChain value from the crosschain balance of current pool
     *  subtract the redeemCurrentChain value from the crosschain balance
     *  of crosschainPool pool
     * @param _lptAmount the amount of liquidity pool tokens to burn
     */
    function setCooldownForLp(uint256 _lptAmount) external payable isUserLiquidityProvider {
        s_cooldown[msg.sender] = block.timestamp;
        s_cooldownAmount[msg.sender] = _lptAmount;

        (uint256 redeemCurrentChain, uint256 redeemCrossChain) = calculateAmountToRedeem(_lptAmount);

        s_crossChainUnderlyingBalance -= redeemCrossChain;

        _sendCCipMessageCooldown(redeemCurrentChain, _lptAmount, getRouter());
    }

    /**
     * @notice mint LPTs to LPs and get the underlyng in exchange
     * @notice LPs cannot deposit crosschain -> they need to switch network if they want to deposit in the other pool
     *  @notice this function send a message updating s_crossChainUnderlyingBalance and s_crossChainLiquidityPoolTokens (adding these values on other pool)
     *
     * @param _token the token to deposit as underlying
     * @param _amount the _amount to deposit as underlying
     */
    function deposit(IERC20 _token, uint256 _amount) external payable isCorrectToken(_token) moreThanZero(_amount) {
        // calculate the LPT to mint
        uint256 lptAmount = calculateLPTinExchangeOfUnderlying(_amount);

        emit DepositedAndMintedLpt(msg.sender, lptAmount, address(i_underlyingToken), _amount, block.chainid);

        // transfer underlying to this contract
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        // mint LPTs tokens to LP
        _mint(msg.sender, lptAmount);

        // send message crosschain to update the amount of this pool to the other pool
        _sendCCipMessageDeposit(_amount, lptAmount, getRouter());
    }

    /**
     * @notice burn amount of LPTs and transfer amount of underlying tokens to LP
     * @notice this function should send a message updating s_crossChainUnderlyingBalance and s_crossChainLiquidityPoolTokens and update it here! (in the current network, I want to subtract what will be redeemed/burned in the other chain)
     *  @notice this function should send a message crosschain giving the right amount of underlying tokens to the LP on the other chain
     *  calculating the amount of tokens to redeem in this and other chain:
     *  1. calculate value of 1 lpt
     *  2. multiply times the n of lpt to burn
     *  3. calculate how much liquidity each pool have in %
     *         lets say here there are 30% weth and on the other chain 70%
     *         the user should get 30% of its burned token on current chain and 70% on the other chain
     *  befoore calling this, the lp should call setCooldownForLp
     * @param _lptAmount the LPT amount to burn
     */
    function redeem(uint256 _lptAmount, address _to)
        external
        payable
        nonReentrant
        isUserLiquidityProvider
        isCooldownPeriodExpired
        isLPRedeemingCorrectAmount(_lptAmount)
    {
        // check that user has funds
        if (balanceOf(msg.sender) < _lptAmount) {
            revert CrossChainPool__NotEnoughBalanceToRedeem();
        }

        (uint256 redeemCurrentChain, uint256 redeemCrossChain) = calculateAmountToRedeem(_lptAmount);

        if (i_underlyingToken.balanceOf(address(this)) < redeemCurrentChain) {
            revert CrossChainPool__NotEnoughBalanceToRedeemCurrentChain();
        }
        if (s_crossChainUnderlyingBalance < redeemCrossChain) {
            revert CrossChainPool__NotEnoughBalanceToRedeemCrossChain();
        }

        emit Redeem(msg.sender, redeemCurrentChain, block.chainid);

        // burn lp
        _burn(msg.sender, _lptAmount);

        // transfer underlying to LP
        i_underlyingToken.safeTransfer(msg.sender, redeemCurrentChain);

        // sending message to redeem crosschain
        _sendCCipMessageRedeem(redeemCrossChain, redeemCurrentChain, _to, getRouter());
    }

    /**
     * @notice add the crosschain sender of the other pool
     *  s_crossChainPool cannot be modified
     */
    function addCrossChainSender(address _sender) external {
        if (s_crossChainPool == address(0)) {
            s_crossChainPool = _sender;
        }
    }

    /**
     * @notice users deposit here underlying tokens and send a message to the other pool crosschain that will send the teleported token to the _to address specified in this function
     *  @notice this function should also send a message updating s_crossChainUnderlyingBalance and also update it here;
     *  @notice this function should be called after forecasting ccipFees
     *  @notice fees are paid in underlying token
     *  @param _value the amount to teleport
     *  @param _to the address to send token on destination chain
     */
    function teleport(uint256 _value, address _to) external payable {
        address router = getRouter();

        // protocol fees
        uint256 fees = calculateBuckleAppFees(_value);

        // user deposit underlying tokens
        emit Teleport(_value, _to, address(i_underlyingToken), i_crossChainSelector);

        i_underlyingToken.safeTransferFrom(msg.sender, address(this), _value);

        // send a message to other pool
        _sendCCipMessageTeleport(_value, fees, _to, router);
    }

    /**
     * @notice set values for gasLimit used by ccip sendMessage functions
     */
    function setGasLimitValues(uint24 _gas_limit) external onlyOwner {
        s_gas_limit = _gas_limit;
    }

    /**
     * @notice set the cooldown period (default 6 hours)
     */
    function setCooldownPeriod(uint24 _period) external onlyOwner {
        s_cooldownPeriod = _period;
    }

    /**
     * @notice set the fee percentage (default 5%)
     */
    function setFeePercentage(uint16 _fee_bps) external onlyOwner {
        s_fee_bps = _fee_bps;
    }

    /*//////////////////////////////////////////////////////////////
                           PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice calculate the correct amount to mint for the input underlying amount
     *  1 LPT = total cross-chain underlying / total crosschain LPT
     * @param _amountOfUnderlyingToDeposit the amount to deposit
     * @custom:assumption we assume the ERC20 always have 18 decimals
     */
    function calculateLPTinExchangeOfUnderlying(uint256 _amountOfUnderlyingToDeposit) public view returns (uint256) {
        uint256 valueOfOneLpt = getValueOfOneLpt();
        uint256 lptAmount = ((_amountOfUnderlyingToDeposit * 1e18) / valueOfOneLpt);
        return lptAmount;
    }

    /**
     * @notice calculate how much the LP would redeem in exchange of LPT amount
     */
    function calculateAmountToRedeem(uint256 _lptAmount)
        public
        view
        returns (uint256 redeemCurrentChain, uint256 redeemCrossChain)
    {
        uint256 precision = 1e24;

        uint256 totalReedemValue = getRedeemValueForLP(_lptAmount);

        (uint256 totaProtocolUnderlying,) = getTotalProtocolBalances();

        uint256 totalUnderlyingHere = i_underlyingToken.balanceOf(address(this));

        uint256 ratioCurrentChain = (totalUnderlyingHere * precision) / totaProtocolUnderlying;

        uint256 ratioCrossChain = (s_crossChainUnderlyingBalance * precision) / totaProtocolUnderlying;

        redeemCurrentChain = (totalReedemValue * ratioCurrentChain) / precision;

        redeemCrossChain = (totalReedemValue * ratioCrossChain) / precision;

        // totaProtocolUnderlying =
        // totalUnderlyingHere    =
        // totalRedeem            =
        // ratioCurrentChain      =
        // ratioCrossChain        =
        // totalRedeem            =
    }

    /**
     * @notice calculate a fixed fee of 5%
     *  @param _value the amount to calc the fees for
     *  @return fees
     */
    function calculateBuckleAppFees(uint256 _value) public view returns (uint256 fees) {
        if ((_value * s_fee_bps) < 10_000) {
            revert CrossChainPool__AmountTooSmall();
        }
        fees = (_value * s_fee_bps) / 10_0000;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL/ PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice convert bytes sneder sent by ccip router to address
     */
    function _bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL: CCIP SEND MESSAGE
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice send a message to the crosschain pool
     *  subtract value to teleport - fees from s_crossChainUnderlyingBalance
     *  fees are retained in destination chain
     */
    function _sendCCipMessageTeleport(uint256 _value, uint256 _fees, address _to, address _router) internal {
        Client.EVM2AnyMessage memory message = _buildTeleportMessage(_value, _fees, _to);

        uint256 ccipFees = IRouterClient(_router).getFee(i_crossChainSelector, message);
        if (msg.value < ccipFees) {
            revert CrossChainPool__UserCCipFeesNotEnough();
        }

        unchecked {
            if (s_crossChainUnderlyingBalance <= _value) {
                revert CrossChainPool__NotEnoughBalanceOnDestinationPool();
            }
        }

        // user is depositing on this network and will withdraw in the other
        s_crossChainUnderlyingBalance -= (_value - _fees);

        s_lastSentMessageId = IRouterClient(_router).ccipSend{value: msg.value}(i_crossChainSelector, message);
    }

    /**
     * @notice send a message for depositing tokens
     */
    function _sendCCipMessageDeposit(
        uint256 _underlyingDepositedAmount,
        uint256 _liquidityTokensMinted,
        address _router
    ) internal {
        Client.EVM2AnyMessage memory message = _buildDepositMessage(_underlyingDepositedAmount, _liquidityTokensMinted);

        uint256 ccipFees = IRouterClient(_router).getFee(i_crossChainSelector, message);
        if (msg.value < ccipFees) {
            revert CrossChainPool__UserCCipFeesNotEnough();
        }

        s_lastSentMessageId = IRouterClient(_router).ccipSend{value: msg.value}(i_crossChainSelector, message);
    }

    /**
     * @notice send message to redeem tokens on destination chain
     */
    function _sendCCipMessageRedeem(
        uint256 _amountToRedeem,
        uint256 _amountRedeemedOnSourceChain,
        address _to,
        address _router
    ) internal {
        Client.EVM2AnyMessage memory message = _buildRedeemMessage(_amountToRedeem, _amountRedeemedOnSourceChain, _to);

        uint256 ccipFees = IRouterClient(_router).getFee(i_crossChainSelector, message);
        if (msg.value < ccipFees) {
            revert CrossChainPool__UserCCipFeesNotEnough();
        }

        s_lastSentMessageId = IRouterClient(_router).ccipSend{value: msg.value}(i_crossChainSelector, message);
    }

    /**
     * @notice send a message for the cooldown
     */
    function _sendCCipMessageCooldown(uint256 _cooldownAmount, uint256 _lptAmount, address _router) internal {
        Client.EVM2AnyMessage memory message = _buildCooldownMessage(_cooldownAmount, _lptAmount);

        uint256 ccipFees = IRouterClient(_router).getFee(i_crossChainSelector, message);
        if (msg.value < ccipFees) {
            revert CrossChainPool__UserCCipFeesNotEnough();
        }

        s_lastSentMessageId = IRouterClient(_router).ccipSend{value: msg.value}(i_crossChainSelector, message);
    }

    /**
     * @notice build the deposit message
     */
    function _buildDepositMessage(uint256 _underlyingDepositedAmount, uint256 _liquidityTokensMinted)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_crossChainPool), // receiver is the pool on destination chain
            data: abi.encode(DEPOSIT_FUNCTION_ID, _underlyingDepositedAmount, _liquidityTokensMinted), //  the parameters to pass into deployPool
            tokenAmounts: new Client.EVMTokenAmount[](0), // we are not passing tokens even tho we bridge bc we cool AF
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: s_gas_limit})
            ),
            feeToken: address(0) // will pay with eth
        });
    }

    /**
     * @notice build the redeem message
     */
    function _buildRedeemMessage(uint256 _amountToRedeem, uint256 _amountRedeemedOnSourceChain, address _to)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_crossChainPool), // receiver is the pool on destination chain
            data: abi.encode(REDEEM_FUNCTION_ID, _amountToRedeem, _amountRedeemedOnSourceChain, _to), //  the parameters to pass into deployPool
            tokenAmounts: new Client.EVMTokenAmount[](0), // we are not passing tokens even tho we bridge bc we cool AF
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: s_gas_limit})
            ),
            feeToken: address(0) // will pay with eth
        });
    }

    /**
     * @notice build the cooldown message
     */
    function _buildCooldownMessage(uint256 _cooldownAmount, uint256 _lptAmount)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_crossChainPool),
            data: abi.encode(COOLDOWN_FUNCTION_ID, _cooldownAmount, _lptAmount),
            tokenAmounts: new Client.EVMTokenAmount[](0), // we are not passing tokens even tho we bridge bc we cool AF
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: s_gas_limit})
            ),
            feeToken: address(0) // will pay with eth
        });
    }

    /**
     * @notice build the teleport message
     */
    function _buildTeleportMessage(uint256 _value, uint256 _fees, address _to)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_crossChainPool),
            data: abi.encode(TELEPORT_FUNCTION_ID, _value, _fees, _to),
            tokenAmounts: new Client.EVMTokenAmount[](0), // we are not passing tokens even tho we bridge bc we cool AF
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: s_gas_limit})
            ),
            feeToken: address(0) // will pay with eth
        });
    }

    /**
     * @notice build the teleport message
     */
    function _simulateMessageTeleport(uint256 _value, address _to)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        uint256 fees = calculateBuckleAppFees(_value);
        message = _buildTeleportMessage(_value, fees, _to);
    }

    /**
     * @notice simulate the deposit message - needed to evaluate the cost of deposit in ccip fees
     */
    function _simulateMessageDeposit(uint256 _underlyingDepositedAmount)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        uint256 lptToMint = calculateLPTinExchangeOfUnderlying(_underlyingDepositedAmount);

        message = _buildDepositMessage(_underlyingDepositedAmount, lptToMint);
    }

    /**
     * @notice @notice simulate the redeem message - needed to evaluate the cost of reedeming in ccip fees
     */
    function _simulateMessageRedeem(uint256 _lptToken, address _to)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        (uint256 redeemCurrentChain, uint256 redeemCrossChain) = calculateAmountToRedeem(_lptToken);

        message = _buildRedeemMessage(redeemCrossChain, redeemCurrentChain, _to);
    }

    /**
     * @notice @notice simulate the cooldown message - needed to evaluate the cost of cooldown in ccip fees
     */
    function _simulateMessageCooldown(uint256 _lptAmount)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        (uint256 redeemCurrentChain,) = calculateAmountToRedeem(_lptAmount);

        message = _buildCooldownMessage(redeemCurrentChain, _lptAmount);
    }

    /**
     * @notice helper function to see if the cooldown period has expired
     */
    function _isCooldownExpired(address lp) internal view returns (bool) {
        return s_cooldown[lp] + (block.timestamp - s_cooldown[lp]) > s_cooldown[lp] + s_cooldownPeriod;
    }

    /*//////////////////////////////////////////////////////////////
                             CCIP RECEIVE MESSAGE
    //////////////////////////////////////////////////////////////*/
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        areSenderAndSelectorAllowed(any2EvmMessage.sender, any2EvmMessage.sourceChainSelector)
    {
        s_lastReceivedMessageId = any2EvmMessage.messageId;

        // first decoding only functionID
        (uint8 functionID) = abi.decode(any2EvmMessage.data, (uint8));

        if (functionID == TELEPORT_FUNCTION_ID) {
            (, uint256 teleportedValue, uint256 feesForTeleporting, address to) =
                abi.decode(any2EvmMessage.data, (uint8, uint256, uint256, address));

            s_crossChainUnderlyingBalance += teleportedValue; //should be + fees
            i_underlyingToken.safeTransfer(to, teleportedValue - feesForTeleporting);
        }
        if (functionID == DEPOSIT_FUNCTION_ID) {
            (, uint256 UnderlyingDeposited, uint256 LiquidityTokensMinted) =
                abi.decode(any2EvmMessage.data, (uint8, uint256, uint256));

            // adding these values to the balance of the other crosschainPool
            s_crossChainUnderlyingBalance += UnderlyingDeposited;
            s_crossChainLiquidityPoolTokens += LiquidityTokensMinted;
        }
        if (functionID == REDEEM_FUNCTION_ID) {
            // NOT subtracting amounts on the source chain from s_crossChainUnderlyingBalance bc I did it already at cooldown

            (, uint256 AmountToRedeem, address to) = abi.decode(any2EvmMessage.data, (uint8, uint256, address));

            // send underlying to to address
            i_underlyingToken.safeTransfer(to, AmountToRedeem);
            emit Redeem(to, AmountToRedeem, block.chainid);
        }
        if (functionID == COOLDOWN_FUNCTION_ID) {
            // todo need to remove the lp from crosschain balance
            (, uint256 _cooldownAmount, uint256 _lptAmount) = abi.decode(any2EvmMessage.data, (uint8, uint256, uint256));
            s_crossChainUnderlyingBalance -= _cooldownAmount;
            s_crossChainLiquidityPoolTokens -= _lptAmount;
        }

        emit MessageReceived(any2EvmMessage.messageId);
    }

    /*//////////////////////////////////////////////////////////////
                             CCIP FEES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice this is used with teleport function to forecast the ccip fees and let the user pay those fees
     */
    function getCcipFeesForTeleporting(uint256 _value, address _to) public view returns (uint256) {
        address router = getRouter();
        Client.EVM2AnyMessage memory message = _simulateMessageTeleport(_value, _to);
        return IRouterClient(router).getFee(i_crossChainSelector, message);
    }

    /**
     * @notice this is used with deposit function to forecast the ccip fees and let the user pay those fees
     */
    function getCCipFeesForDeposit(uint256 _value) public view returns (uint256) {
        address router = getRouter();
        Client.EVM2AnyMessage memory message = _simulateMessageDeposit(_value);
        return IRouterClient(router).getFee(i_crossChainSelector, message);
    }

    /**
     * @notice this is used with redeem function to forecast the ccip fees and let the user pay those fees
     */
    function getCCipFeesForRedeem(uint256 _lptAmount, address _to) public view returns (uint256) {
        address router = getRouter();
        Client.EVM2AnyMessage memory message = _simulateMessageRedeem(_lptAmount, _to);
        return IRouterClient(router).getFee(i_crossChainSelector, message);
    }

    /**
     * @notice this is used with cooldown function to forecast the ccip fees and let the user pay those fees
     */
    function getCCipFeesForCooldown(uint256 _lptAmount) public view returns (uint256) {
        address router = getRouter();
        Client.EVM2AnyMessage memory message = _simulateMessageCooldown(_lptAmount);
        return IRouterClient(router).getFee(i_crossChainSelector, message);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice get the underlyng token for this pool
     */
    function getUnderlyingToken() external view returns (IERC20) {
        return i_underlyingToken;
    }

    /**
     * @notice get the balances of the pool on the other chain
     */
    function getCrossChainBalances()
        external
        view
        returns (uint256 crossChainUnderlyingBalance, uint256 crossChainLiquidityPoolTokens)
    {
        return (s_crossChainUnderlyingBalance, s_crossChainLiquidityPoolTokens);
    }

    /**
     * @notice get the cooldown timestamp for the lp
     */
    function getCooldown(address lp) external view returns (uint256, bool) {
        return (s_cooldown[lp], _isCooldownExpired(lp));
    }

    /*//////////////////////////////////////////////////////////////
                         PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice get the allowed pool and chain
     */
    function getCrossChainSenderAndSelector() public view returns (address, uint64) {
        return (s_crossChainPool, i_crossChainSelector);
    }

    /**
     * @notice get the address of the underlying crosschain
     */
    function getOtherChainUnderlyingToken() public view returns (address) {
        return address(i_otherChainUnderlyingToken);
    }

    /**
     * @notice get the sum of the protocol balance (sum the balances in this chain and in the other chain)
     */
    function getTotalProtocolBalances() public view returns (uint256 totalUnderlyingBal, uint256 totalLptBal) {
        totalUnderlyingBal = s_crossChainUnderlyingBalance + i_underlyingToken.balanceOf(address(this));
        totalLptBal = s_crossChainLiquidityPoolTokens + totalSupply();
    }

    /**
     * @notice calculate the value of 1 lpt on the entire protocol
     */
    function getValueOfOneLpt() public view returns (uint256 value) {
        uint256 totalCrossChainUnderlyingAmount =
            i_underlyingToken.balanceOf(address(this)) + s_crossChainUnderlyingBalance;

        // total lpts on current pool + total lpt on other chain
        uint256 totalCrossChainLPTAmount = totalSupply() + s_crossChainLiquidityPoolTokens;

        if (totalCrossChainLPTAmount == 0) {
            // in this case the ratio is 1 to 1 because we have 0 LPT and 0 underlying
            return 1e18;
        }

        value = ((totalCrossChainUnderlyingAmount * 1e18) / totalCrossChainLPTAmount);
    }

    /**
     * @notice get how much lp get back from the lpt amount
     */
    function getRedeemValueForLP(uint256 _lptAmount) public view returns (uint256 reedemValue) {
        reedemValue = (_lptAmount * getValueOfOneLpt()) / 1e18;
    }

    /**
     * @notice get the gas limit needed to send ccip messages
     */
    function getGasLimitValues() public view returns (uint256) {
        return s_gas_limit;
    }
}
