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

// import {Script, console2} from "forge-std/Script.sol";
import {CCIPReceiver} from "ccip/contracts/ccip/applications/CCIPReceiver.sol";
import {Client} from "ccip/contracts/ccip/libraries/Client.sol";
import {IRouterClient} from "ccip/contracts/ccip/interfaces/IRouterClient.sol";

import {AggregatorV3Interface} from "ccip/contracts/shared/interfaces/AggregatorV3Interface.sol";
// import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
// import {VRFV2PlusClient} from "@chainlink/contracts/vrf/dev/libraries/VRFV2PlusClient.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {CrossChainPool} from "./CrossChainPool.sol";
import {Register} from "./Register.sol";
/**
 * @notice this contract deploy simultaneusly 2 pools on 2 networks
 * todo there should be a function to allow different networks
 * in inherit from chainlink ccip contracts
 * has an external function that anyone could call to deploy a crosschain pool pair
 *  the deployer is the owner of the contract
 *  deployer need to sen feetoken to this contract beforehand
 */

contract PoolFactory is Ownable, CCIPReceiver, Register {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error PoolFactory__PoolDeploymentFailed();
    error PoolFactory__CrossChainDeploymentFailed(bytes call);

    /*//////////////////////////////////////////////////////////////
                            TYPES DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 private s_lastReceivedMessageId;
    bytes32 private s_lastSentMessageId;
    bytes private s_lastReceivedData;
    address private immutable i_feeToken;
    uint64 private constant DEPLOY_POOL_FUNCTION_ID = 1;
    uint64 private immutable i_chainSelectorCurrentChain;
    uint256 private s_nonce;
    mapping(uint64 => address[]) private s_deployedPoolsOnOtherChains; //  maps chain selector to pool array
    address[] private s_allDeployedPoolsInCurrentChain; //  maps chain selector to pool array
    AggregatorV3Interface private s_priceFeed;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event PoolCreated(
        address indexed pool,
        address indexed tokenCurrentChain,
        address indexed tokenCrossChain,
        uint64 crosschainSelector
    );
    event DeployCCSuccess(
        address indexed deployedPool,
        address indexed underlyingOnCurrentChain,
        string indexed poolName,
        uint64 sourceChainSelector,
        address underlyingTokenOnOtherChain
    );
    event FeeTokenDeposited(address indexed sender);
    event FeeTokenWithdrawn();
    event RandomSalt();

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address _ccipRouter, address _feeToken, uint64 _chainSelector, address _priceFeed)
        CCIPReceiver(_ccipRouter)
        Ownable(msg.sender)
    {
        i_feeToken = _feeToken;
        i_chainSelectorCurrentChain = _chainSelector;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice start the crosschain deployment flow. deploy pools using ccip and create2
     *  @param _receiverFactory the address of the receiver factory
     *  @param _underlyingTokenOnSourceChain the underlying ERC20 token on current network
     *  @param _underlyingTokenOnDestinationChain the underlying ERC20 token on destination network
     *  @param _destinationChainId the destination chain id
     *  @param _poolName name of pool
     */
    function deployCCPoolsCreate2(
        address _receiverFactory,
        address _underlyingTokenOnSourceChain,
        address _underlyingTokenOnDestinationChain,
        uint256 _destinationChainId,
        string memory _poolName
    ) external returns (address) {
        NetworkDetails memory destinationConfig = s_networkDetails[_destinationChainId];
        uint256 salt = s_nonce + 1;
        s_nonce += 1;

        address deployedPool = _deployPoolCreate2(
            _underlyingTokenOnSourceChain,
            _poolName,
            destinationConfig.chainSelector,
            _underlyingTokenOnDestinationChain,
            salt
        );

        address receiverFactory = _receiverFactory;
        address destinationPoolComputedAddress = _computeAddress(
            salt,
            _underlyingTokenOnDestinationChain,
            _poolName,
            i_chainSelectorCurrentChain,
            destinationConfig.routerAddress,
            _underlyingTokenOnSourceChain,
            receiverFactory
        );

        CrossChainPool(deployedPool).addCrossChainSender(destinationPoolComputedAddress);

        s_deployedPoolsOnOtherChains[destinationConfig.chainSelector].push(destinationPoolComputedAddress);

        _sendCCipMessageDeploy(
            _receiverFactory,
            destinationConfig.chainSelector,
            _underlyingTokenOnDestinationChain,
            _poolName,
            deployedPool,
            _underlyingTokenOnSourceChain,
            salt
        );
        // _requestRandomWords();
        return deployedPool;
    }

    /**
     * @notice used by the owner to deposit the fee token
     * @param _amount amount of fee token to deposit
     */
    function depositFeeToken(uint256 _amount) external {
        IERC20(i_feeToken).safeTransferFrom(msg.sender, address(this), _amount);
        // _requestRandomWords();

        emit FeeTokenDeposited(msg.sender);
    }

    /**
     * @notice used by the owner to withdraw all the fee token
     */
    function withdrawFeeToken() external onlyOwner {
        uint256 balance = IERC20(i_feeToken).balanceOf(address(this));
        IERC20(i_feeToken).safeTransfer(msg.sender, balance);
        emit FeeTokenWithdrawn();
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL / PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice deploy pool on the current chain using create2
     */
    function _deployPoolCreate2(
        address _underlyingToken,
        string memory _name,
        uint64 _crossChainSelector,
        address _underlyingTokenOnDestinationChain,
        uint256 _salt
    ) internal returns (address poolAddress) {
        address router = getRouter();

        bytes memory bytecode = type(CrossChainPool).creationCode;
        bytes memory encodedByteCodeAndParams = abi.encodePacked(
            bytecode,
            abi.encode(_underlyingToken, _name, _crossChainSelector, router, _underlyingTokenOnDestinationChain)
        );
        poolAddress = Create2.deploy(0, bytes32(_salt), encodedByteCodeAndParams);

        emit PoolCreated(poolAddress, _underlyingToken, _underlyingTokenOnDestinationChain, _crossChainSelector);
        s_allDeployedPoolsInCurrentChain.push(poolAddress);
        return poolAddress;
    }

    /**
     * @notice compute the address of the pool that will be deployed on destination chain
     */
    function _computeAddress(
        uint256 _salt,
        address _underlyingToken,
        string memory _name,
        uint64 _crossChainSelector,
        address _destinationRouterAddress,
        address _underlyingTokenOnDestinationChain,
        address _receiverFactory
    ) internal pure returns (address) {
        bytes memory bytecode = type(CrossChainPool).creationCode;
        bytes memory encodedByteCodeAndParams = abi.encodePacked(
            bytecode,
            abi.encode(
                _underlyingToken,
                _name,
                _crossChainSelector,
                _destinationRouterAddress,
                _underlyingTokenOnDestinationChain
            )
        );

        bytes32 bytecodeHash = keccak256(encodedByteCodeAndParams);
        return Create2.computeAddress(bytes32(_salt), bytecodeHash, _receiverFactory);
    }

    /**
     * @notice send a message crosschain to another factory to deploy a pool contract
     * @notice deployer should send fee token to this contract
     * @param _receiver the other factory on the destination chain
     * @param _destinationChainSelector the destination chain chainlink selector id
     * @param _underlyingOnOtherChain the address of the underlying token on the destination chain
     * @param _name name of pool
     * @param _deployedPoolAddress the deployed pool to add as a allowed sender
     * @param _underlyingTokenOnSourceChain the address of the underlying token on the current chain
     */
    function _sendCCipMessageDeploy(
        address _receiver,
        uint64 _destinationChainSelector,
        address _underlyingOnOtherChain,
        string memory _name,
        address _deployedPoolAddress,
        address _underlyingTokenOnSourceChain,
        uint256 _salt
    ) internal {
        address router = getRouter(); // it is the chainlink router for the current network

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode(
                DEPLOY_POOL_FUNCTION_ID,
                _underlyingOnOtherChain,
                _name,
                _deployedPoolAddress,
                _underlyingTokenOnSourceChain,
                _salt
            ), //  the parameters to pass into _deployPool
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 3_000_000})
            ),
            feeToken: i_feeToken
        });

        uint256 fee = IRouterClient(router).getFee(_destinationChainSelector, message);

        IERC20(i_feeToken).approve(address(router), fee);

        s_lastSentMessageId = IRouterClient(router).ccipSend(_destinationChainSelector, message);
    }

    /**
     * @notice inherits form ccipReceiver and allow the contract to receive messages from other factories
     *  @notice it should deploy a new pool in the network where this contract is received
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
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        s_lastReceivedData = any2EvmMessage.data;
        (
            uint64 functionID,
            address underlyingOnCurrentChain,
            string memory poolName,
            address deployedPoolOnOtherChain,
            address underlyingTokenOnOtherChain,
            uint256 salt
        ) = abi.decode(any2EvmMessage.data, (uint64, address, string, address, address, uint256));
        address deployedPool;
        if (functionID == DEPLOY_POOL_FUNCTION_ID) {
            s_nonce += 1;
            deployedPool = _deployPoolCreate2(
                underlyingOnCurrentChain,
                poolName,
                any2EvmMessage.sourceChainSelector,
                underlyingTokenOnOtherChain,
                salt
            );
            CrossChainPool(deployedPool).addCrossChainSender(deployedPoolOnOtherChain);
            s_deployedPoolsOnOtherChains[any2EvmMessage.sourceChainSelector].push(deployedPoolOnOtherChain);
        }

        emit DeployCCSuccess(
            deployedPool,
            underlyingOnCurrentChain,
            poolName,
            any2EvmMessage.sourceChainSelector,
            underlyingTokenOnOtherChain
        );
    }

    /// @notice use vrf to make a salt
    // function _requestRandomWords() internal onlyOwner returns (uint256) {
    //     bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}));
    //     (uint256 requestId, uint256 reqPrice) = requestRandomness(uint32(100000), uint16(3), uint32(2), extraArgs);
    //     return requestId;
    // }

    // function fulfillRandomWords(
    //     uint256,
    //     /**
    //      * _requestId
    //      */
    //     uint256[] memory _randomWords
    // ) internal override {
    //     s_lastRandomSalt = _randomWords[0];
    //     emit RandomSalt();
    // }
    /*//////////////////////////////////////////////////////////////
                         PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fetches the details of the last received message.
     * @return s_lastReceivedMessageId The ID of the last received message.
     * @return s_lastReceivedData the data last received message.
     */
    function getLastReceivedMessageDetails() external view returns (bytes32, bytes memory) {
        return (s_lastReceivedMessageId, s_lastReceivedData);
    }

    /**
     * @return s_lastSentMessageId The ID of the last sent message.
     */
    function getLastSentMsg() external view returns (bytes32) {
        return s_lastSentMessageId;
    }

    /**
     * @return i_feeToken
     */
    function getFeeToken() external view returns (address) {
        return address(i_feeToken);
    }

    /**
     * @return i_ccipRouter
     */
    function getCcipRouter() external view returns (address) {
        return i_ccipRouter;
    }

    /**
     * @notice returns all the deployed pools for a ccip chain selectori
     * @param _chainSelector the ccip chain selector
     */
    function getALlDeployedPoolsForChainSelector(uint64 _chainSelector) external view returns (address[] memory) {
        return s_deployedPoolsOnOtherChains[_chainSelector];
    }

    function getDeployedPoolsInCurrenChain() external view returns (address[] memory) {
        return s_allDeployedPoolsInCurrentChain;
    }

    function getLinkUsdPrice() external view returns (int256) {
        (, int256 answer,,,) = s_priceFeed.latestRoundData();
        return answer;
    }
}
