// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/*//////////////////////////////////////////////////////////////
        this file is for unit tests on PoolFactory.sol
//////////////////////////////////////////////////////////////*/

import {Test} from "forge-std/Test.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {Config} from "../../script/helper/Config.sol";
import {Register} from "./helpers/Register.sol";
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

    // cant be tested as it is bc _ccipReceive is internal skip for now
    // function testGetALlDeployedPoolsForChainSelector() public {
    //     uint64 mockChainSelector = 123;

    //     poolFactorySourceChain.deployCCPools(address(1), address(2), address(3), mockChainSelector, "test");

    //     address[] memory list = poolFactorySourceChain.getALlDeployedPoolsForChainSelector(mockChainSelector);

    //     assertGt(list.length, 0);
    // }
}
