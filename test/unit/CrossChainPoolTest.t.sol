// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {CrossChainPool} from "../../src/CrossChainPool.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DeployCrossChainPool} from "../../script/DeployCrossChainPool.s.sol";

// todo update it with real pks
contract CrossChainPoolTest is Test {
    CrossChainPool public crossChainPool;
    address public LP = address(1);
    ERC20Mock public underlying;
    uint256 public STARTING_DEPOSIT = 1e18;

    modifier deposited() {
        // minting the underlying to user
        // create a new user and impersonate him
        vm.startPrank(LP);
        // call deposit
        underlying.approve(address(crossChainPool), STARTING_DEPOSIT);
        crossChainPool.deposit(underlying, STARTING_DEPOSIT);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        DeployCrossChainPool deployCrossChainPool = new DeployCrossChainPool();
        crossChainPool = deployCrossChainPool.run();

        underlying = deployCrossChainPool.underlying();
        underlying.mint(LP, 1000e18);
    }

    function testPoolDeployment() public {
        string memory expectedName = crossChainPool.name();
        assertEq(expectedName, "crossChainPoolTest");
    }

    function testFirstDeposit() public deposited {
        // check lptAmount expected
        uint256 LPBalanceLpt = crossChainPool.balanceOf(LP);
        assertEq(LPBalanceLpt, STARTING_DEPOSIT);
    }

    function testSubsequentsDeposit(uint256 numberOfDeposit) public {
        if (numberOfDeposit >= 1000) return;
        // minting the underlying to user
        // create a new user and impersonate him
        vm.startPrank(LP);
        // call deposit

        underlying.approve(address(crossChainPool), type(uint256).max);
        for (uint256 i = 0; i < numberOfDeposit; i++) {
            crossChainPool.deposit(underlying, STARTING_DEPOSIT);
        }
        vm.stopPrank();

        // check lptAmount expected
        uint256 LPBalanceLpt = crossChainPool.balanceOf(LP);
        assertEq(LPBalanceLpt, STARTING_DEPOSIT * numberOfDeposit);
    }

    function testRedeem() public deposited {
        uint256 valueToBurn = 1e17;
        //call reedem
        vm.startPrank(LP);
        // approving LPT
        crossChainPool.approve(address(crossChainPool), valueToBurn); // i'm not sure, dbc
        crossChainPool.redeem(valueToBurn, LP);
        vm.stopPrank();

        // check that the balance of LPT is burnt correctly
        assertEq(crossChainPool.balanceOf(LP), STARTING_DEPOSIT - valueToBurn);
    }

    function testCalculatingFees() public deposited {
        uint256 amPlusFees = crossChainPool.getCCipFeesForDeposit(1e18);
        // should be 1e18 + 5 % of 1e18
        assertEq(amPlusFees, 5e15);
    }
}
