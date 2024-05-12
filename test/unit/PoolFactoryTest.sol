// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";

import {DeployPoolFactory} from "../../script/DeployPoolFactory.s.sol";

contract PoolFactoryTest is Test {
    PoolFactory public poolFactorySourceChain;
    PoolFactory public poolFactoryDestinationChain;

    function setUp() public {
        DeployPoolFactory deployPoolFactory = new DeployPoolFactory();

        poolFactorySourceChain = deployPoolFactory.run();
        poolFactoryDestinationChain = deployPoolFactory.run();
    }

    function testPoolFactoryDeployment() public view {
        assertNotEq(address(poolFactorySourceChain), address(0));
        assertNotEq(address(poolFactoryDestinationChain), address(0));
    }
}
