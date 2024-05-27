// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {CrossChainPool} from "../../src/CrossChainPool.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DeployCrossChainPool} from "../../script/DeployCrossChainPool.s.sol";
import {MockRouter} from "./mock/MockRouter.sol";

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
        uint256 ccipFees = 1; // simulating it

        // call deposit
        underlying.approve(address(crossChainPool), STARTING_DEPOSIT);
        crossChainPool.deposit{value: ccipFees}(underlying, STARTING_DEPOSIT);
        console2.log("balance of pool after deposit", underlying.balanceOf(address(crossChainPool)));
        assertEq(underlying.balanceOf(address(crossChainPool)), STARTING_DEPOSIT);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        underlying = new ERC20Mock();
        MockRouter mockRouter = new MockRouter();
        ERC20Mock crossChainUnderlying = new ERC20Mock();
        DeployCrossChainPool deployCrossChainPool = new DeployCrossChainPool();

        crossChainPool =
            deployCrossChainPool.run(address(underlying), address(crossChainUnderlying), address(mockRouter));

        underlying.mint(LP, 1000e18);
        vm.deal(LP, 1000 ether);
    }

    function testPoolDeployment() public view {
        string memory expectedName = crossChainPool.name();
        assertEq(expectedName, "BUCKLEcrossChainPoolTest");
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
        uint256 ccipFees = 1;
        underlying.approve(address(crossChainPool), type(uint256).max);
        for (uint256 i = 0; i < numberOfDeposit; i++) {
            crossChainPool.deposit{value: ccipFees}(underlying, STARTING_DEPOSIT);
        }
        vm.stopPrank();

        // check lptAmount expected
        uint256 LPBalanceLpt = crossChainPool.balanceOf(LP);
        assertEq(LPBalanceLpt, STARTING_DEPOSIT * numberOfDeposit);
    }

    function testRedeem() public deposited {
        uint256 valueToBurn = 1e17; //lpts
        // 100000000000000000 vm
        //call reedem
        vm.startPrank(LP);
        // approving LPT
        crossChainPool.approve(address(crossChainPool), valueToBurn); // i'm not sure, dbc
        crossChainPool.setCooldownForLp{value: 1}(valueToBurn);
        vm.warp(block.timestamp + 24 hours);
        crossChainPool.redeem{value: 1}(valueToBurn, LP);
        vm.stopPrank();

        // check that the balance of LPT is burnt correctly
        assertEq(crossChainPool.balanceOf(LP), STARTING_DEPOSIT - valueToBurn);
    }

    function testCalculatingCCipFees() public deposited {
        uint256 ccipDepositFees = crossChainPool.getCCipFeesForDeposit(1e18);
        assertEq(ccipDepositFees, 1);
    }
}
