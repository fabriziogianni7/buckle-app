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

// import {Test, console2} from "forge-std/Test.sol";

import {CrossChainPool} from "./CrossChainPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CCIPReceiver} from "ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "ccip/contracts/libraries/Client.sol";
import {IRouterClient} from "ccip/contracts/interfaces/IRouterClient.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @notice this contract deploy simultaneusly 2 pools on 2 networks
 * todo there should be a function to allow different networks
 * in inherit from chainlink ccip contracts
 * has an external function that anyone could call to deploy a crosschain pool pair
 *  the deployer is the owner of the contract
 *  deployer need to sen feetoken to this contract beforehand
 */

contract PoolFactory is Ownable, CCIPReceiver {
    // errors
    error PoolFactory__PoolDeploymentFailed();
    error PoolFactory__CrossChainDeploymentFailed(bytes call);
    // interfaces, libraries, contracts
    // Type declarations

    using SafeERC20 for IERC20;

    // State variables
    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    bytes32 private s_lastSentMessageId; // Store the last received messageId.
    bytes private s_lastReceivedData; // Store the last received text.
    address private immutable i_feeToken;
    uint64 private constant DEPLOY_POOL_FUNCTION_ID = 1;
    uint64 private constant SUCCESS_DEPLOY_FUNCTION_ID = 2;
    mapping(uint64 => address[]) private s_deployedPools; //  maps chain selector to pool array

    // Events
    event PoolCreated(
        address indexed pool,
        address indexed tokenCurrentChain,
        address indexed tokenCrossChain,
        uint64 crosschainSelector
    );
    event MessageReceived(bytes32 indexed messageId);
    event FeeTokenDeposited(address indexed sender);
    event FeeTokenWithdrawn();

    // Modifiers

    // Functions

    constructor(address _ccipRouter, address _feeToken) CCIPReceiver(_ccipRouter) Ownable(msg.sender) {
        i_feeToken = _feeToken;
    }

    // external

    /**
     * @notice start the crosschain deployment flow
     * it get called by a user that want to deploy new pool pairs
     * the user should:
     *     1. select 2 networks
     * the contract should:
     *     1. deploy pool on current network
     *     2. send ccip message to factory on other networks
     *      on the destination network, it should be deployed the correspondent pool
     *  @param _receiverFactory the address of the receiver factory
     *  @param _underlyingTokenOnSourceChain the underlying ERC20 token on current network
     *  @param _underlyingTokenOnDestinationChain the underlying ERC20 token on destination network
     *  @param _destinationChainSelector the chain selector from ccip of the destination network
     *  @param _poolName name of pool
     */
    function deployCCPools(
        address _receiverFactory,
        address _underlyingTokenOnSourceChain,
        address _underlyingTokenOnDestinationChain,
        uint64 _destinationChainSelector,
        string memory _poolName
    ) external returns (address) {
        (address deployedPool, bool success) = _deployPool(
            _underlyingTokenOnSourceChain, _poolName, _destinationChainSelector, _underlyingTokenOnDestinationChain
        );
        if (!success) {
            revert PoolFactory__PoolDeploymentFailed();
        }
        _sendCCipMessageDeploy(
            _receiverFactory,
            _destinationChainSelector,
            _underlyingTokenOnDestinationChain,
            _poolName,
            deployedPool,
            _underlyingTokenOnSourceChain
        );
        return deployedPool;
    }

    function depositFeeToken(uint256 _amount) external {
        IERC20(i_feeToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit FeeTokenDeposited(msg.sender);
    }

    function withdrawFeeToken() external onlyOwner {
        uint256 balance = IERC20(i_feeToken).balanceOf(address(this));
        IERC20(i_feeToken).safeTransfer(msg.sender, balance);
        emit FeeTokenWithdrawn();
    }

    // public

    // internal/ private

    function _deployPool(
        address _underlyingToken,
        string memory _name,
        uint64 _crossChainSelector,
        address _underlyingTokenOnDestinationChain
    ) internal returns (address poolAddress, bool success) {
        // todo make necessary checks
        address router = getRouter();
        CrossChainPool pool =
            new CrossChainPool(_underlyingToken, _name, _crossChainSelector, router, _underlyingTokenOnDestinationChain);
        poolAddress = address(pool);
        if (poolAddress == address(0)) {
            success = false;
        } else {
            success = true;
        }

        emit PoolCreated(poolAddress, _underlyingToken, _underlyingTokenOnDestinationChain, _crossChainSelector);
        return (poolAddress, success);
    }

    /**
     * @notice send a message crosschain to another factory to deploy a pool contract
     * @notice deployer should send fee token to this contract
     * @param receiver the other factory on the other chain
     * @param destinationChainSelector the destination chain chainlink selector id
     * @param _deployedPoolAddress the deployed pool to add as a allowed sender
     */
    function _sendCCipMessageDeploy(
        address receiver,
        uint64 destinationChainSelector,
        address _underlyingOnOtherChain,
        string memory _name,
        address _deployedPoolAddress,
        address _underlyingTokenOnSourceChain
    ) internal {
        address router = getRouter(); // it is the chainlink router for the current network

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // receiver is the factory on destination chain
            data: abi.encode(
                DEPLOY_POOL_FUNCTION_ID, _underlyingOnOtherChain, _name, _deployedPoolAddress, _underlyingTokenOnSourceChain
            ), //  the parameters to pass into _deployPool
            tokenAmounts: new Client.EVMTokenAmount[](0), // we are not passing tokens even tho we bridge bc we cool AF
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 3_000_000})
            ),
            feeToken: i_feeToken // the token this contract will pay with
        });

        uint256 fee = IRouterClient(router).getFee(destinationChainSelector, message);

        IERC20(i_feeToken).approve(address(router), fee);

        s_lastSentMessageId = IRouterClient(router).ccipSend(destinationChainSelector, message);
    }

    /**
     * @notice send back a message to source chain when the deployment is successful
     * @param _receiver the factory from the source chain
     * @param _destinationChainSelector the ccip selector of the chain to send the message
     * @param _deployedPoolAddress the pool address which was deployed
     */
    function _sendCCipMessageDeploySuccess(
        address _receiver,
        uint64 _destinationChainSelector,
        address _deployedPoolAddress,
        address _deployedPoolOnOtherChain
    ) internal {
        address router = getRouter(); // it is the chainlink router for the current network

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // receiver is the factory on destination chain
            data: abi.encode(SUCCESS_DEPLOY_FUNCTION_ID, _deployedPoolAddress, "", _deployedPoolOnOtherChain, address(0)), //  the parameters to pass into _deployPool
            tokenAmounts: new Client.EVMTokenAmount[](0), // we are not passing tokens even tho we bridge bc we cool AF
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 400_000})
            ),
            // _207_625
            // 2_000_000
            feeToken: i_feeToken // the token this contract will pay with
        });

        uint256 fee = IRouterClient(router).getFee(_destinationChainSelector, message);

        IERC20(i_feeToken).approve(address(router), fee);

        s_lastSentMessageId = IRouterClient(router).ccipSend(_destinationChainSelector, message);
        // consider emit event here
    }

    /**
     * @notice inherits form ccipReceiver and allow the contract to receive messages from other factories
     *  @notice it should deploy a new pool in the network where this contract is received
     *  todo should allow just a smart contract to send messages here (make check)
     *  should be ready to accept  3 type of msgs:
     *     pool deployment request
     *     succesfull deployment ack
     *     failure on deployment
     *
     *  should trigger the send of 2 type of msgs, success (address of deployed pool) and fail msg (address(0))
     *
     *     selector defines the type of received msg
     */
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        // uint256 startGas = gasleft();
        s_lastReceivedMessageId = any2EvmMessage.messageId;

        // those are the parameters
        s_lastReceivedData = any2EvmMessage.data; // maybe delete this line

        (
            uint64 functionID,
            address underlyingTokenOrDeployedAddress,
            string memory poolName,
            address peerDeployedPool,
            address underlyingTokenOnOtherChain
        ) = abi.decode(any2EvmMessage.data, (uint64, address, string, address, address)); // abi-decoding of the sent text

        if (functionID == DEPLOY_POOL_FUNCTION_ID) {
            // todo find a good way to handle error here
            (address deployedPool, bool success) = _deployPool(
                underlyingTokenOrDeployedAddress,
                poolName,
                any2EvmMessage.sourceChainSelector,
                underlyingTokenOnOtherChain
            );
            if (success) {
                //add the allowed sender -deployedPoolOnOtherChain- to the pool
                CrossChainPool(deployedPool).addCrossChainSender(peerDeployedPool);
                // send a fail msg
                _sendCCipMessageDeploySuccess(
                    abi.decode(any2EvmMessage.sender, (address)),
                    any2EvmMessage.sourceChainSelector,
                    deployedPool, // current chain
                    peerDeployedPool // source chain
                );
                //todo emit an event here with the deployed pool
            } else {
                revert PoolFactory__PoolDeploymentFailed();
            }
        }

        // @todo send a fail msg if something goes wrong

        // here is when I receive the "ACK" telling that the deployment is ok
        //receving it from destination chain
        // @todo think about a better way to avoid using mapping uint -> address array
        if (functionID == SUCCESS_DEPLOY_FUNCTION_ID) {
            s_deployedPools[any2EvmMessage.sourceChainSelector].push(underlyingTokenOrDeployedAddress);

            // in this function peerDeployedPool is actually the deployed pool in the current network
            CrossChainPool(peerDeployedPool).addCrossChainSender(underlyingTokenOrDeployedAddress);
        }

        emit MessageReceived(any2EvmMessage.messageId);
        // uint256 endGas = gasleft();
        // uint256 totalSpent = startGas - endGas;
    }

    // view fucntions
    /// @notice Fetches the details of the last received message.
    /// @return messageId The ID of the last received message.
    /// @return data the data last received message.
    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, bytes memory data) {
        return (s_lastReceivedMessageId, s_lastReceivedData);
    }

    function getALlDeployedPoolsForChainSelector(uint64 chainSelector) external view returns (address[] memory) {
        return s_deployedPools[chainSelector];
    }
}
