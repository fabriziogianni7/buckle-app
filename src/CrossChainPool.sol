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

import {console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CCIPReceiver} from "ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "ccip/contracts/libraries/Client.sol";
import {IRouterClient} from "ccip/contracts/interfaces/IRouterClient.sol";

/**
 * @notice
 * This contract is deployed in pair with the same token on another chain
 * eg.
 *     I deploy CrossChainPoolWETH on Base and deploy CrossChainPoolWETH on Arb
 *     those 2 contracts will be able to exchange liquidity crosschain
 * @custom:functionalities
 *  Users can bridge tokens to the other network
 *  Contract should forward tokens bridged from the other network
 *  LPs can deposit underlying and get LPTs in exchange
 *  LPs can withdraw underlying and burn LPTS
 * @custom:roles
 *  there are 2 roles:
 *     users: the ones that use this contracts as a bridge
 *     LPs: users which put liquidity on the pools
 * @custom:formulas
 *  1LPT = total crosschain underlying / total crosschain LPTS
 * @custom:invariant
 * we want the ratio between underlying tokens and LPTs always > 1
 *  @custom:interfaces
 *     inherit from CCIP contracts and functions contracts
 */
contract CrossChainPool is ERC20, ReentrancyGuard, CCIPReceiver {
    // errors
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

    // interfaces, libraries, contracts

    // Type declarations
    using SafeERC20 for IERC20;

    // State variables
    IERC20 private immutable i_underlyingToken;
    IERC20 private immutable i_otherChainUnderlyingToken;
    uint64 private immutable i_crossChainSelector;
    address private s_crossChainPool;
    bytes32 private s_lastSentMessageId;
    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    mapping(address => uint256) private readyToWithdraw;

    uint8 private constant TELEPORT_FUNCTION_ID = 1;
    uint8 private constant DEPOSIT_FUNCTION_ID = 2;
    uint8 private constant REDEEM_FUNCTION_ID = 3;
    uint256 private FEES_BPS = 500;

    uint256 private s_crossChainUnderlyingBalance;
    uint256 private s_crossChainLiquidityPoolTokens;

    // Events
    event DepositedAndMintedLpt(address indexed lp, uint256 indexed lptAmount, uint256 indexed underlyingAmount);
    event RedeemedCurrentChain(
        address indexed lp, uint256 indexed lptAmountBurnt, uint256 indexed underlyingAmount, uint256 chainid
    );
    event RedeemedCrossChain(
        address indexed lp, uint256 indexed underlyingAmount, uint256 chainid, bytes32 indexed messageId
    );
    event TeleportStarted(uint256 indexed value, address indexed to);
    event MessageReceived(bytes32 indexed messageId);

    // Modifiers
    modifier areSenderAndSelectorAllowed(address _sender, uint64 _selector) {
        (address allowedSender, uint64 allowedSelector) = getCrossChainSenderAndSelector();

        if (allowedSender != _sender || allowedSelector != _selector) {
            revert CrossChainPool__SenderOrSelectorNotAllowed();
        }

        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert CrossChainPool__ShouldBeMoreThanZero();
        }
        _;
    }

    modifier isCorrectToken(IERC20 token) {
        if (token != i_underlyingToken) {
            revert CrossChainPool__WrongUnderlying();
        }
        _;
    }

    modifier isUserLiquidityProvider() {
        if (balanceOf(msg.sender) <= 0) {
            revert CrossChainPool__NotLP();
        }
        _;
    }
    // Functions

    // @todo the ERC20 should have a better name specifying the networks
    /**
     * @notice instantiate the pool
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
    ) ERC20(_name, "LPT") CCIPReceiver(_router) {
        i_underlyingToken = IERC20(_underlyingToken);
        i_otherChainUnderlyingToken = IERC20(_otherChainUnderlyingToken);
        i_crossChainSelector = _crossChainSelector;
    }

    // external
    /**
     * @notice mint LPTs to LPs and get the underlyng in exchange
     * @notice LPs cannot deposit crosschain -> they need to switch network if they want to deposit in the other pool
     *  @notice this function should send a message updating s_crossChainUnderlyingBalance and s_crossChainLiquidityPoolTokens (adding these values on other pool)
     *
     * @param _token the token to deposit as underlying
     * @param _amount the _amount to deposit as underlying
     * @custom:security follow CEI pattern Cecks Effects Interactions
     */
    function deposit(IERC20 _token, uint256 _amount) external payable isCorrectToken(_token) moreThanZero(_amount) {
        // calculate the LPT to mint
        uint256 lptAmount = calculateLPTinExchangeOfUnderlying(_amount);

        emit DepositedAndMintedLpt(msg.sender, lptAmount, _amount);

        // transfer underlying to this contract
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        // mint LPTs tokens to LP
        _mint(msg.sender, lptAmount);

        // send message crosschain to update the amount of this pool to the other pool
        _sendCCipMessageDeposit(_amount, lptAmount, getRouter());
    }

    /**
     * @notice burn amount of LPs and transfer amount of underlying tokens to LP
     *  @notice this function should send a message updating s_crossChainUnderlyingBalance and s_crossChainLiquidityPoolTokens and update it here! (in the current network, I want to subtract what will be redeemed/burned in the other chain)
     *  @notice this function should send a message crosschain giving the right part of underlying to the LP crosschain
     *  calculating the am of tokens to redeem in this and other chain:
     *  1. calculate value of 1 lpt
     *  2. multiply times the n of lpt to burn
     *  3. calculate how much liquidity each pool have in %
     *         lets say here there are 30% weth and on the other chain 70%
     *         the user should get 30% of its burned token here and 70% there
     * @param _lptAmount the LPT amount to burn
     */
    function redeem(uint256 _lptAmount, address _to) external payable nonReentrant isUserLiquidityProvider {
        // check that user has funds
        if (balanceOf(msg.sender) < _lptAmount) {
            revert CrossChainPool__NotEnoughBalanceToRedeem();
        }

        (uint256 redeemCurrentChain, uint256 redeemCrossChain) = calculateAmountToRedeem(_lptAmount);
        console2.log("redeemCurrentChain", redeemCurrentChain);
        console2.log("underlying in pool", balanceOf(address(this)));

        if (i_underlyingToken.balanceOf(address(this)) < redeemCurrentChain) {
            revert CrossChainPool__NotEnoughBalanceToRedeemCurrentChain();
        }
        if (s_crossChainUnderlyingBalance < redeemCrossChain) {
            revert CrossChainPool__NotEnoughBalanceToRedeemCrossChain();
        }

        emit RedeemedCurrentChain(msg.sender, _lptAmount, redeemCurrentChain, block.chainid);

        // burn lp
        _burn(msg.sender, _lptAmount);

        // transfer underlying to LP
        i_underlyingToken.safeTransfer(msg.sender, redeemCurrentChain);

        // sending message to redeem crosschain
        _sendCCipMessageRedeem(redeemCrossChain, redeemCurrentChain, _to, getRouter());
    }

    /**
     * @notice add the crosschain sender of the other pool
     * todo add access control
     */
    function addCrossChainSender(address _sender) external {
        s_crossChainPool = _sender;
    }

    /**
     * @notice users deposit here underlying token and send a message to the other pool crosschain to make the teleportation of the tokens
     *  @notice this function should also send a message updating s_crossChainUnderlyingBalance and also update here;
     *  @notice this function should be called after forecasting ccipFees
     *  @notice fees are paid in underlying token
     *  @param _value the amount to teleport
     *  @param _to the address to send token on destination chain
     */
    function teleport(uint256 _value, address _to) external payable {
        address router = getRouter();

        // add the amount to the count of teleported amount to account it later for LP fees

        // user deposit underlying tokens
        emit TeleportStarted(_value, _to);

        // protocol fees
        uint256 fees = calculateBuckleAppFees(_value);
        i_underlyingToken.safeTransferFrom(msg.sender, address(this), _value);
        // send a message to other pool
        _sendCCipMessageTeleport(_value, fees, _to, router);
    }

    // function teleportTransfer() external {} --> send tokens bridged from th other network to user, receive a message from ccip (maybe internal)

    // public
    /**
     * @notice calculate the correct amount to mint for the input underlying amount
     *  1 LPT = total cross-chain underlying / total crosschain LPT
     * formula: totalDeposit / valueOfOneLpt
     * @param _amountOfUnderlyingToDeposit the amount to deposit
     * @custom:assumption we assume the ERC20 always have 18 decimals
     */
    function calculateLPTinExchangeOfUnderlying(uint256 _amountOfUnderlyingToDeposit) public view returns (uint256) {
        uint256 valueOfOneLpt = getValueOfOneLpt();
        uint256 lptAmount = ((_amountOfUnderlyingToDeposit * 1e18) / valueOfOneLpt);
        // uint256 lptAmount = ((_amountOfUnderlyingToDeposit * 1e5) / valueOfOneLpt) * 1e13;
        // // console2.log("lptAmount", lptAmount);
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
        uint256 precision = 1e18;
        uint256 totalReedemValue = getRedeemValueForLP(_lptAmount);
        // console2.log("totalReedemValue", totalReedemValue);

        (uint256 totaProtocolUnderlying,) = getTotalProtocolBalances();
        // console2.log("totaProtocolUnderlying", totaProtocolUnderlying);
        // calculate how much to withdraw in each chain
        uint256 totalUnderlyingHere = i_underlyingToken.balanceOf(address(this));

        // console2.log("totalUnderlyingHere", totalUnderlyingHere);

        uint256 ratioCurrentChain = (totalUnderlyingHere * precision) / totaProtocolUnderlying;

        // console2.log("ratioCurrentChain", ratioCurrentChain);

        uint256 ratioCrossChain = (s_crossChainUnderlyingBalance * precision) / totaProtocolUnderlying;

        // console2.log("ratioCrossChain", ratioCrossChain);

        redeemCurrentChain = (totalReedemValue * ratioCurrentChain) / precision;
        redeemCrossChain = (totalReedemValue * ratioCrossChain) / precision;

        // console2.log("redeemCurrentChain", redeemCurrentChain);
        // console2.log("redeemCrossChain", redeemCrossChain);
        // console2.log("sum", redeemCrossChain + redeemCurrentChain);
    }

    /**
     * @notice calculate a fixed fee of 5%
     *  @param _value the amount to calc the fees for
     *  @return fees
     */
    function calculateBuckleAppFees(uint256 _value) public view returns (uint256 fees) {
        if ((_value * FEES_BPS) < 10_000) {
            revert CrossChainPool__AmountTooSmall();
        }

        fees = (_value * FEES_BPS) / 10_0000;
    }

    // internal

    ///////// CCIP SEND MESSAGE /////////

    function _sendCCipMessageTeleport(uint256 _value, uint256 _fees, address _to, address _router) internal {
        Client.EVM2AnyMessage memory message = _buildTeleportMessage(_value, _fees, _to);

        uint256 ccipFees = IRouterClient(_router).getFee(i_crossChainSelector, message);
        if (msg.value < ccipFees) {
            revert CrossChainPool__UserCCipFeesNotEnough();
        }

        unchecked {
            // if the balance on other chain is less than 0, revert
            // check for gas improvement here
            if (s_crossChainUnderlyingBalance <= _value) {
                revert CrossChainPool__NotEnoughBalanceOnDestinationPool();
            }
        }

        // user is depositing on this network and will withdraw in the other
        s_crossChainUnderlyingBalance -= (_value - _fees);

        s_lastSentMessageId = IRouterClient(_router).ccipSend{value: msg.value}(i_crossChainSelector, message);
    }

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

    /// see CCIPReceiver.sol
    // todo add events for each functionID
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId;

        (
            uint8 functionID,
            uint256 valueOrUnderlyingDepositedAmountOrAmountToRedeem,
            uint256 feesOrLiquidityTokensMintedOrRedeemedAmount,
            address to
        ) = abi.decode(any2EvmMessage.data, (uint8, uint256, uint256, address));

        if (functionID == TELEPORT_FUNCTION_ID) {
            // add
            s_crossChainUnderlyingBalance += valueOrUnderlyingDepositedAmountOrAmountToRedeem; //should be + fees
            i_underlyingToken.safeTransfer(
                to, valueOrUnderlyingDepositedAmountOrAmountToRedeem - feesOrLiquidityTokensMintedOrRedeemedAmount
            ); //todo review this
        }
        if (functionID == DEPOSIT_FUNCTION_ID) {
            // adding these values to the balance of the other crosschainPool
            s_crossChainUnderlyingBalance += valueOrUnderlyingDepositedAmountOrAmountToRedeem;
            s_crossChainLiquidityPoolTokens += feesOrLiquidityTokensMintedOrRedeemedAmount;
        }
        if (functionID == REDEEM_FUNCTION_ID) {
            // subtract amount redeemed on the source chain from s_crossChainUnderlyingBalance
            s_crossChainUnderlyingBalance -= feesOrLiquidityTokensMintedOrRedeemedAmount;

            // send underlying to to address
            i_underlyingToken.safeTransfer(to, valueOrUnderlyingDepositedAmountOrAmountToRedeem);
            emit RedeemedCrossChain(
                to, valueOrUnderlyingDepositedAmountOrAmountToRedeem, block.chainid, any2EvmMessage.messageId
            );
        }
        emit MessageReceived(any2EvmMessage.messageId);
    }

    function _buildDepositMessage(uint256 _underlyingDepositedAmount, uint256 _liquidityTokensMinted)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_crossChainPool), // receiver is the pool on destination chain
            data: abi.encode(DEPOSIT_FUNCTION_ID, _underlyingDepositedAmount, _liquidityTokensMinted, address(0)), //  the parameters to pass into deployPool
            tokenAmounts: new Client.EVMTokenAmount[](0), // we are not passing tokens even tho we bridge bc we cool AF
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 3_000_000})
            ),
            feeToken: address(0) // will pay with eth
        });
    }

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
                Client.EVMExtraArgsV1({gasLimit: 3_000_000})
            ),
            feeToken: address(0) // will pay with eth
        });
    }

    function _simulateMessageTeleport(uint256 _value, address _to)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        uint256 fees = calculateBuckleAppFees(_value);
        message = _buildTeleportMessage(_value, fees, _to);
    }

    function _simulateMessageDeposit(uint256 _underlyingDepositedAmount)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        uint256 lptToMint = calculateLPTinExchangeOfUnderlying(_underlyingDepositedAmount);

        message = _buildDepositMessage(_underlyingDepositedAmount, lptToMint);
    }

    function _simulateMessageRedeem(uint256 _lptToken, address _to)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        (uint256 redeemCurrentChain, uint256 redeemCrossChain) = calculateAmountToRedeem(_lptToken);

        message = _buildRedeemMessage(redeemCrossChain, redeemCurrentChain, _to);
    }

    function _buildTeleportMessage(uint256 _value, uint256 _fees, address _to)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_crossChainPool), // receiver is the pool on destination chain
            data: abi.encode(TELEPORT_FUNCTION_ID, _value, _fees, _to), //  the parameters to pass into deployPool
            // data: abi.encode(TELEPORT_FUNCTION_ID, _value - _fees, _fees, _to), //  the parameters to pass into deployPool
            tokenAmounts: new Client.EVMTokenAmount[](0), // we are not passing tokens even tho we bridge bc we cool AF
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 3_000_000})
            ),
            feeToken: address(0) // will pay with eth
        });
    }

    ///////// CCIP FEES /////////

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

    function getCCipFeesForRedeem(uint256 _lptAmount, address _to) public view returns (uint256) {
        address router = getRouter();
        Client.EVM2AnyMessage memory message = _simulateMessageRedeem(_lptAmount, _to);
        return IRouterClient(router).getFee(i_crossChainSelector, message);
    }

    // view fucntions
    function getUnderlyingToken() external view returns (IERC20) {
        return i_underlyingToken;
    }

    function getCrossChainSenderAndSelector() public view returns (address, uint64) {
        return (s_crossChainPool, i_crossChainSelector);
    }

    function getOtherChainUnderlyingToken() public view returns (address) {
        return address(i_otherChainUnderlyingToken);
    }

    function getCrossChainBalances()
        external
        view
        returns (uint256 crossChainUnderlyingBalance, uint256 crossChainLiquidityPoolTokens)
    {
        return (s_crossChainUnderlyingBalance, s_crossChainLiquidityPoolTokens);
    }

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

        // value = ((totalCrossChainUnderlyingAmount * 1e5) / totalCrossChainLPTAmount) * 1e13;
        value = ((totalCrossChainUnderlyingAmount * 1e18) / totalCrossChainLPTAmount);
    }

    function getRedeemValueForLP(uint256 _lptAmount) public view returns (uint256 reedemValue) {
        reedemValue = (_lptAmount * getValueOfOneLpt()) / 1e18;
    }
}
