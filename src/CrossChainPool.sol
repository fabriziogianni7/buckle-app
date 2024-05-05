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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
contract CrossChainPool is ERC20, ReentrancyGuard {
    // errors
    error CrossChainPool__ShouldBeMoreThanZero();
    error CrossChainPool__WrongUnderlying();
    error CrossChainPool__NotLP();
    // interfaces, libraries, contracts
    // Type declarations

    using SafeERC20 for IERC20;
    // State variables

    IERC20 private immutable i_underlyingToken;
    // Events

    event DepositedAndMintedLpt(address indexed lp, uint256 indexed lptAmount, uint256 indexed underlyingAmount);
    event Redeemed(address indexed lp, uint256 indexed lptAmountBurnt, uint256 indexed underlyingAmount);

    // Modifiers

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
    constructor(IERC20 _underlyingToken, string memory _name) ERC20(_name, "LPT") {
        i_underlyingToken = _underlyingToken;
    }

    // external
    /**
     * @notice mint LPTs to LPs and get the underlyng in exchange
     * @notice follow CEI pattern Cecks Effects Interactions
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
    // bridgeTo() --> send a ccip message on other chain
    // getBridgedToken() --> send tokens bridged from th other network to user, receive a message from ccip (maybe internal)

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
    // isEnoughBalanceOnOtherChain() --> check pending ccip messages and subtract total amount pending from total amount on pool contract ()on other chain)

    // view fucntions
    function getUnderlyingToken() external view returns (IERC20) {
        return i_underlyingToken;
    }
}
