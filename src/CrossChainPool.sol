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
import {CCIPReceiver} from "ccip/applications/CCIPReceiver.sol";
import {Client} from "ccip/libraries/Client.sol";
import {IRouterClient} from "ccip/interfaces/IRouterClient.sol";

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
    error CrossChainPool__UserFeesNotEnough();
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
    uint8 private constant TELEPORT_SUCCESS_FUNCTION_ID = 2;
    uint8 private constant TELEPORT_FAIL_FUNCTION_ID = 3;

    // Events
    event DepositedAndMintedLpt(address indexed lp, uint256 indexed lptAmount, uint256 indexed underlyingAmount);
    event Redeemed(address indexed lp, uint256 indexed lptAmountBurnt, uint256 indexed underlyingAmount);
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
     * @notice follow CEI pattern Cecks Effects Interactions
     * @notice LPs cannot deposit crosschain -> they need to switch network if they want to deposit in the other pool
     *  @param _token the token to deposit as underlying
     *  @param _amount the _amount to deposit as underlying
     */
    function deposit(IERC20 _token, uint256 _amount) external isCorrectToken(_token) moreThanZero(_amount) {
        // calculate the LPT to mint
        uint256 lptAmount = calculateLPTinExchangeOfUnderlying(_amount);

        emit DepositedAndMintedLpt(msg.sender, lptAmount, _amount);

        // transfer underlying to this contract
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        // mint LPTs tokens to LP
        _mint(msg.sender, lptAmount);
    }

    /**
     * @notice burn amount of LPs and transfer amount of underlying tokens to LP
     * @param _lptAmount the LPT amount to burn
     */
    function redeem(uint256 _lptAmount) external nonReentrant isUserLiquidityProvider {
        uint256 underlyingAmount = calculateUnderlyingInExchangeOfLPT(_lptAmount);

        emit Redeemed(msg.sender, _lptAmount, underlyingAmount);

        // transfer underlying yo LP
        i_underlyingToken.safeTransfer(msg.sender, underlyingAmount);

        // burn lp
        _burn(msg.sender, _lptAmount);
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
     *  @param _value the amount to teleport
     *  @param _to the address to send token on destination chain
     */
    function startTeleport(uint256 _value, address _to) external payable {
        address router = getRouter();

        // at this point this contract should have enough money to pay fee

        // user deposit underlying tokens
        emit TeleportStarted(_value, _to);
        // todo calculate fees and add it to value
        i_underlyingToken.safeTransferFrom(msg.sender, address(this), _value);
        // send a message to other pool
        _sendCCipMessageTeleport(_value, _to, router);
    }

    // function teleportTransfer() external {} --> send tokens bridged from th other network to user, receive a message from ccip (maybe internal)

    // public
    /**
     * @notice calculate the correct amount to mint for the input underlying amount
     *  1 LPT = total cross-chain underlying / total crosschain LPT
     * formula: _amount * (total cross-chain underlying / total crosschain LPT)
     * @param _amount the amount to deposit
     * @custom:assumption we assume the ERC20 always have 18 decimals
     * @custom:todo implement with ccip
     */
    function calculateLPTinExchangeOfUnderlying(uint256 _amount) public view returns (uint256) {
        uint256 totalCrossChainUnderlyingAmount = i_underlyingToken.balanceOf(address(this));
        uint256 totalCrossChainLPTAmount = totalSupply();
        if (totalCrossChainLPTAmount == 0) {
            return _amount; // in this case the ratio is 1 to 1 because we have 0 LPT and 0 underlying
        }
        uint256 lptAmount = _amount * (totalCrossChainUnderlyingAmount / totalCrossChainLPTAmount);
        return lptAmount;
    }

    /**
     * @notice calculate the amount of underlying token LP get in exchange of  LPT tokens
     *  1 underlying = total crosschain LPT / total cross-chain underlying
     * @param _amount the amount to exchange
     * @custom:assumption we assume the ERC20 always have 18 decimals
     */
    function calculateUnderlyingInExchangeOfLPT(uint256 _amount) public view returns (uint256) {
        uint256 totalCrossChainUnderlyingAmount = i_underlyingToken.balanceOf(address(this));
        uint256 totalCrossChainLPTAmount = totalSupply();
        if (totalCrossChainLPTAmount == 0) {
            return _amount; // in this case the ratio is 1 to 1 because we have 0 LPT and 0 underlying
        }
        uint256 underlyingAmount = _amount * (totalCrossChainLPTAmount / totalCrossChainUnderlyingAmount);
        return underlyingAmount;
    }

    // internal
    function _sendCCipMessageTeleport(uint256 _value, address _to, address _router) internal {
        Client.EVM2AnyMessage memory message = _buildTeleportMessage(_value, _to);

        uint256 fee = IRouterClient(_router).getFee(i_crossChainSelector, message);
        if (msg.value < fee) {
            revert CrossChainPool__UserFeesNotEnough();
        }

        s_lastSentMessageId = IRouterClient(_router).ccipSend{value: msg.value}(i_crossChainSelector, message);
    }

    function _buildTeleportMessage(uint256 _value, address _to)
        internal
        view
        returns (Client.EVM2AnyMessage memory message)
    {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_crossChainPool), // receiver is the pool on destination chain
            data: abi.encode(TELEPORT_FUNCTION_ID, _value, _to), //  the parameters to pass into deployPool
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
        message = _buildTeleportMessage(_value, _to);
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId;

        (uint8 functionID, uint256 value, address to) = abi.decode(any2EvmMessage.data, (uint8, uint256, address));

        if (functionID == TELEPORT_FUNCTION_ID) {
            // add
            console2.log("i_underlyingToken", address(i_underlyingToken));
            i_underlyingToken.safeTransfer(to, value); //todo review this
            console2.log("balance after transfer", i_underlyingToken.balanceOf(to));

            // sending  positive ack if transfer is success todo how do I pay for it?
        }
        emit MessageReceived(any2EvmMessage.messageId);
    }
    // isEnoughBalanceOnOtherChain() --> check pending ccip messages and subtract total amount pending from total amount on pool contract ()on other chain)

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

    /**
     * @notice this is used with startTeleport function to forecast the fees and let the user pay those fees
     *  todo add the fees for the liquidity provider later on
     */
    function getFeesForTeleporting(uint256 _value, address _to) public view returns (uint256) {
        address router = getRouter();
        Client.EVM2AnyMessage memory message = _simulateMessageTeleport(_value, _to);
        return IRouterClient(router).getFee(i_crossChainSelector, message);
    }
}
