// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/*//////////////////////////////////////////////////////////////
        this file is for unit tests on PoolFactory.sol
//////////////////////////////////////////////////////////////*/

import {Test, console2} from "forge-std/Test.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {Config} from "../../script/helper/Config.sol";
import {Register} from "../helpers/Register.sol";
import {DeployPoolFactory} from "../../script/deploy/DeployPoolFactory.s.sol";

contract PoolFactoryTest is Test {
    PoolFactory public poolFactorySourceChain;
    PoolFactory public poolFactoryDestinationChain;
    Config public config;
    Register.NetworkDetails public activeConfig;

    address public DEPLOYER = address(103);

    function setUp() public {
        DeployPoolFactory deployPoolFactory = new DeployPoolFactory();
        deployPoolFactory.setUp();

        config = deployPoolFactory.config();
        activeConfig = config.getActiveNetworkConfig();

        ERC20Mock(activeConfig.linkAddress).mint(DEPLOYER, 100e18);

        vm.prank(DEPLOYER);
        poolFactorySourceChain = deployPoolFactory.run();

        vm.prank(DEPLOYER);
        poolFactoryDestinationChain = deployPoolFactory.run();
    }

    function testPoolFactoryDeployment() public view {
        assertNotEq(address(poolFactorySourceChain), address(0));
        assertNotEq(address(poolFactoryDestinationChain), address(0));
    }

    function testGetters() public view {
        address feeToken = poolFactorySourceChain.getFeeToken();
        assertEq(feeToken, activeConfig.linkAddress);

        address ccipRouter = poolFactorySourceChain.getCcipRouter();
        assertEq(ccipRouter, activeConfig.routerAddress);
    }

    function testDeployPoolCreate2() public {
        TestPoolFactory testPoolFactory =
            new TestPoolFactory(activeConfig.routerAddress, activeConfig.linkAddress, activeConfig.chainSelector);
        TestPoolFactory testPoolFactoryB =
            new TestPoolFactory(activeConfig.routerAddress, activeConfig.linkAddress, activeConfig.chainSelector);

        address _underlyingToken = address(123);
        string memory _name = "create2test";
        uint64 _crossChainSelector = 1;
        address _underlyingTokenOnDestinationChain = address(123);
        address _destinationRouterAddress = 0x20067a7558168e12ad53b235F2f7408FeEa4985F;
        address _receiverFactory = address(testPoolFactoryB);
        uint256 _salt = 1;

        address deployedPoolCreate2 = testPoolFactoryB.deployPoolCreate2(
            _underlyingToken, _name, _crossChainSelector, _underlyingTokenOnDestinationChain, _salt
        );

        address computedAddress = testPoolFactory.computeAddress(
            _salt,
            _underlyingToken,
            _name,
            _crossChainSelector,
            _underlyingTokenOnDestinationChain,
            _destinationRouterAddress,
            _receiverFactory
        );

        assertEq(deployedPoolCreate2, computedAddress);
    }
}

// test contract for the create2 functions / internal function
contract TestPoolFactory is PoolFactory {
    constructor(address _ccipRouter, address _feeToken, uint64 _selector)
        PoolFactory(_ccipRouter, _feeToken, _selector, address(0))
    {}

    function deployPoolCreate2(
        address _underlyingToken,
        string memory _name,
        uint64 _crossChainSelector,
        address _underlyingTokenOnDestinationChain,
        uint256 _salt
    ) public returns (address) {
        return
            _deployPoolCreate2(_underlyingToken, _name, _crossChainSelector, _underlyingTokenOnDestinationChain, _salt);
    }

    function computeAddress(
        uint256 _salt,
        address _underlyingToken,
        string memory _name,
        uint64 _crossChainSelector,
        address _underlyingTokenOnDestinationChain,
        address _destinationRouterAddress,
        address _receiverFactory
    ) public view returns (address) {
        return _computeAddress(
            _salt,
            _underlyingToken,
            _name,
            _crossChainSelector,
            _destinationRouterAddress,
            _underlyingTokenOnDestinationChain,
            _receiverFactory
        );
    }
}
