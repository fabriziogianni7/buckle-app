// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DeployPoolFactory} from "../../script/DeployPoolFactory.s.sol";
import {ChainlinkLocalHelper} from "./helpers/ChainlinkLocalHelper.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// todo update it with real pks
contract CrossChainPoolTest is Test {
    PoolFactory public poolFactorySourceChain;
    PoolFactory public poolFactoryDestinationChain;
    uint64 public chainSelector;
    address public feeToken;
    ERC20Mock public underlying;

    function setUp() public {
        ChainlinkLocalHelper chainlinkLocalHelper = new ChainlinkLocalHelper();
        chainlinkLocalHelper.run(address(this));
        address sourceRouter = address(chainlinkLocalHelper.sourceRouter());
        address destinationRouter = address(chainlinkLocalHelper.destinationRouter());
        chainSelector = chainlinkLocalHelper.chainSelector();
        feeToken = address(chainlinkLocalHelper.linkToken());
        DeployPoolFactory deployPoolFactory = new DeployPoolFactory();
        underlying = new ERC20Mock();

        poolFactorySourceChain = deployPoolFactory.run(sourceRouter, feeToken);
        poolFactoryDestinationChain = deployPoolFactory.run(destinationRouter, feeToken);
    }

    function testPoolFactoryDeployment() public {
        assertNotEq(address(poolFactorySourceChain), address(0));
        assertNotEq(address(poolFactoryDestinationChain), address(0));
    }

    function testSendAndReceiveMsg() public {
        // send link to the contracts
        IERC20(feeToken).transfer(address(poolFactorySourceChain), 10e18);
        IERC20(feeToken).transfer(address(poolFactoryDestinationChain), 10e18);

        // call deployCCPools
        poolFactorySourceChain.deployCCPools(
            chainSelector, "deadpool", underlying, address(poolFactoryDestinationChain)
        );

        (, string memory lastReceivedText) = poolFactoryDestinationChain.getLastReceivedMessageDetails();
        console.log("lastReceivedText %s", lastReceivedText);
        assertEq(lastReceivedText, "Subscribe to fabriziogianni7 yt channel");
    }
}
