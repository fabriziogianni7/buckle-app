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

import {CrossChainPool} from "./CrossChainPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CCIPReceiver} from "ccip/applications/CCIPReceiver.sol";
import {Client} from "ccip/libraries/Client.sol";
import {IRouterClient} from "ccip/interfaces/IRouterClient.sol";

/**
 * @notice this contract deploy simultaneusly 2 pools on 2 networks
 * there should be a function to allow different networks
 * in inherit from chainlink ccip contracts todo, check which?
 * has an external function that anyone could call to deploy a crosschain pool pair
 *  todo should use clone patter to generate
 *  the deployer is the owner of the contract
 *  deployer should send feetoken to this contract!
 */
contract PoolFactory is Ownable, CCIPReceiver {
    // errors
    error PoolFactory__CrossChainDeploymentFailed(bytes call);
    // interfaces, libraries, contracts
    // Type declarations

    // State variables
    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    bytes32 private s_lastSentMessageId; // Store the last received messageId.
    string private s_lastReceivedCalldata; // Store the last received text.
    address private immutable i_feeToken;

    // Events
    event PoolCreated(address indexed pool);
    // The unique ID of the CCIP message.
    // The chain selector of the source chain.
    // The address of the sender from the source chain.
    // The text that was received.
    event MessageReceivedAndPoolDeployed(
        bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, address pool
    );

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
     *      on other network, should be deployed the correspondent pool
     *      the return
     *  @param destinationChainSelector id of destination network
     *  @param _poolName name of pool
     */
    function deployCCPools(
        uint64 destinationChainSelector,
        string memory _poolName,
        address _underlyingToken,
        address receiverFactory
    ) external returns (address) {
        address deployedPool = deployPool(_underlyingToken, _poolName);
        _sendCCipMessage(receiverFactory, destinationChainSelector);
        return deployedPool;
    }

    // public
    // todo check that only ccip can call it (or owner?)
    function deployPool(address _underlyingToken, string memory _name) public returns (address poolAddress) {
        // todo make necessary checks
        IERC20 underlyingToken = IERC20(_underlyingToken);
        CrossChainPool pool = new CrossChainPool(_underlyingToken, _name);
        poolAddress = address(pool);
        emit PoolCreated(poolAddress);
        return poolAddress;
    }

    // internal/ private

    /**
     * @notice send a message crosschain to another factory to deploy a pool contract
     * @notice deployer should send fee token to this contract
     * @param receiver the other factory on the other chain
     * @param destinationChainSelector the destination chain chainlink selector id
     */
    function _sendCCipMessage(
        address receiver,
        uint64 destinationChainSelector,
        address _underlyingOnOtherChain,
        string memory _name
    ) internal {
        address router = getRouter();
        bytes4 SELECTOR = bytes4(keccak256("deployPool(address,string)"));
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeWithSelector(SELECTOR, _underlyingOnOtherChain, _name),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 500_000})
            ),
            feeToken: i_feeToken
        });

        uint256 fee = IRouterClient(router).getFee(destinationChainSelector, message);

        //deployer will send feetokens to this contract
        IERC20(i_feeToken).approve(address(router), fee);

        s_lastSentMessageId = IRouterClient(router).ccipSend(destinationChainSelector, message);
    }

    /**
     * @notice inherits form ccipReceiver and allow the contract to receive messages from other factories
     *  todo it should deploy a new pool in the network where this contract is received
     *  todo should allow just a smart contract to send messages here
     *  todo finish implmentation
     */
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId

        // those are the parameters
        s_lastReceivedCalldata = any2EvmMessage.data;
        // s_lastReceivedCalldata = abi.decode(any2EvmMessage.data, (address, string)); // abi-decoding of the sent text

        (bool success, address deployedAddress) = address(this).call(any2EvmMessage.data);

        if (!success) {
            //should send back a message reverting the originating call from source chain --> no pool is created then
            //todo send back a message to source chain
            revert PoolFactory__CrossChainDeploymentFailed(any2EvmMessage.data);
        }

        // abi.encodeWithSignature("deployPool(address,string)", dataOrder)

        emit MessageReceivedAndPoolDeployed(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            deployedAddress
        );
    }

    // view fucntions
    /// @notice Fetches the details of the last received message.
    /// @return messageId The ID of the last received message.
    /// @return text The last received text.
    function getLastReceivedMessageDetails() external view returns (bytes32 messageId, string memory text) {
        return (s_lastReceivedMessageId, s_lastReceivedCalldata);
    }
}
