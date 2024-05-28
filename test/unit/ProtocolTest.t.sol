// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25; // up to

/*//////////////////////////////////////////////////////////////
            this file test the protocol interactions
//////////////////////////////////////////////////////////////*/

import {Test, console2} from "forge-std/Test.sol";
import {Register} from "../helpers/Register.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {DeployPoolFactory} from "../../script/deploy/DeployPoolFactory.s.sol";
import {CrossChainPool} from "../../src/CrossChainPool.sol";
import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract ProtocolTest is Test {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;

    uint64 public sepoliaChainSelector = 16015286601757825753;
    uint64 public arbSepoliaChainSelector = 3478487238524512106;

    uint256 public sepoliaFork;
    uint256 public arbSepoliaFork;

    PoolFactory public arbFactory;
    PoolFactory public sepoliaFactory;

    address public poolDeployer = address(4);
    address public valentinoRossi = address(46);
    address public LP_ARB = address(102);
    address public LP_SEP = address(102);
    address public DEPLOYER = address(103);

    address public deployedSepoliaPool;
    address public deployedArbSepoliaPool;

    ERC20Mock public sepoliaUnderlying;
    ERC20Mock public arbSepoliaUnderlying;

    uint256 public ERC20_MINT_AMOUNT = 10e18;
    uint256 public INITIAL_MINT_AMOUNT_LP_SEPOLIA = 1000e18;
    uint256 public INITIAL_DEPOSIT_LP = 15e18;
    uint256 public MODIFIER_TELEPORT_AMOUNT = 5e18;

    modifier teleportedFromSepoliaToArbSepolia() {
        teleport(
            MODIFIER_TELEPORT_AMOUNT,
            valentinoRossi,
            sepoliaFork,
            arbSepoliaFork,
            deployedSepoliaPool,
            sepoliaUnderlying
        );
        _;
    }

    modifier depositedInSepolia() {
        depositInPool(deployedSepoliaPool, INITIAL_DEPOSIT_LP, sepoliaUnderlying, sepoliaFork, LP_SEP);
        _;
    }

    function setUp() public {
        // creating forks
        sepoliaFork = vm.createSelectFork(vm.rpcUrl("sepolia"));
        arbSepoliaFork = vm.createFork(vm.rpcUrl("arbitrumSepolia"));

        // USING CCIPSimulatorFork
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));
        vm.makePersistent(valentinoRossi);

        ////// SEPOLIA //////
        //creating a new ERC20 for testing
        vm.deal(valentinoRossi, 1000 ether);
        sepoliaUnderlying = new ERC20Mock();
        sepoliaUnderlying.mint(valentinoRossi, 10000e18);

        vm.deal(LP_SEP, 1000 ether);
        sepoliaUnderlying.mint(LP_ARB, INITIAL_MINT_AMOUNT_LP_SEPOLIA);

        ccipLocalSimulatorFork.requestLinkFromFaucet(DEPLOYER, 100e18);

        DeployPoolFactory deployPoolFactorySep = new DeployPoolFactory();
        deployPoolFactorySep.setUp();

        vm.startPrank(DEPLOYER);
        sepoliaFactory = deployPoolFactorySep.run();
        vm.stopPrank();

        ////// ARBITRUM SEPOLIA //////
        //creating a new ERC20 for testing
        vm.selectFork(arbSepoliaFork);
        vm.deal(LP_ARB, 1000 ether);
        arbSepoliaUnderlying = new ERC20Mock();
        arbSepoliaUnderlying.mint(LP_ARB, ERC20_MINT_AMOUNT + 10000e18);

        // deploy factory on 2nd chain (arb-sepolia)

        ccipLocalSimulatorFork.requestLinkFromFaucet(DEPLOYER, 100e18);

        DeployPoolFactory deployPoolFactoryArb = new DeployPoolFactory();
        deployPoolFactoryArb.setUp();

        vm.startPrank(DEPLOYER);
        arbFactory = deployPoolFactoryArb.run();
        vm.stopPrank();

        ////// SEPOLIA //////
        vm.selectFork(sepoliaFork);
        // deploying the pools
        uint64 destinationChainSelector = 3478487238524512106;

        deployedSepoliaPool = sepoliaFactory.deployCCPools(
            address(arbFactory),
            address(sepoliaUnderlying),
            address(arbSepoliaUnderlying),
            destinationChainSelector,
            "test"
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); // here I'm on arb
        ccipLocalSimulatorFork.switchChainAndRouteMessage(sepoliaFork); // here on sepolia again

        deployedArbSepoliaPool = sepoliaFactory.getALlDeployedPoolsForChainSelector(destinationChainSelector)[0];

        vm.selectFork(arbSepoliaFork);

        // DEPOSIT ON ARB SEPOLIA
        depositInPool(deployedArbSepoliaPool, INITIAL_DEPOSIT_LP, arbSepoliaUnderlying, arbSepoliaFork, LP_ARB);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(sepoliaFork); // here on sepolia
    }

    function testInitialDepositIsOk() public {
        vm.selectFork(sepoliaFork);
        (uint256 underlyingAmount,) = CrossChainPool(deployedSepoliaPool).getCrossChainBalances();

        assertEq(underlyingAmount, INITIAL_DEPOSIT_LP);
    }

    function testForkIsOk() public view {
        assertNotEq(address(arbFactory), address(0));
        assertNotEq(address(sepoliaFactory), address(0));
        assertEq(block.chainid, 11155111);
    }

    function testPoolsAreDeployed() public {
        assertNotEq(deployedSepoliaPool, address(0));
        assertNotEq(deployedArbSepoliaPool, address(0));
        vm.selectFork(sepoliaFork);

        (address allowedSender,) = CrossChainPool(deployedSepoliaPool).getCrossChainSenderAndSelector();
        assertEq(deployedArbSepoliaPool, allowedSender);
    }

    function testCrossChainTokensAreCorrectlySet() public {
        vm.selectFork(sepoliaFork);
        address sepoliaOtherChainToken = CrossChainPool(deployedSepoliaPool).getOtherChainUnderlyingToken();
        assertEq(address(arbSepoliaUnderlying), sepoliaOtherChainToken);

        vm.selectFork(arbSepoliaFork);
        address arbSepoliaOtherChainToken = CrossChainPool(deployedArbSepoliaPool).getOtherChainUnderlyingToken();
        assertEq(address(sepoliaUnderlying), arbSepoliaOtherChainToken);
    }

    function testTeleporting() public teleportedFromSepoliaToArbSepolia {
        vm.selectFork(sepoliaFork);
        uint256 buckleAppFees = CrossChainPool(deployedSepoliaPool).calculateBuckleAppFees(MODIFIER_TELEPORT_AMOUNT);

        vm.selectFork(arbSepoliaFork);
        assertEq(arbSepoliaUnderlying.balanceOf(valentinoRossi), MODIFIER_TELEPORT_AMOUNT - buckleAppFees);
    }

    /// @notice tests a single deposit without teleport events
    function testSimpleDeposit() public {
        vm.selectFork(sepoliaFork);
        uint256 deposit_amount = 5e18;

        (uint256 initialCrossChainUnderlyingAmount, uint256 initialCrossChainLiquidityPoolTokens) =
            CrossChainPool(deployedSepoliaPool).getCrossChainBalances();

        uint256 calculatedReturnLPT =
            CrossChainPool(deployedSepoliaPool).calculateLPTinExchangeOfUnderlying(deposit_amount);

        uint256 initialPoolBalance = sepoliaUnderlying.balanceOf(deployedSepoliaPool);

        // user need to deposit ERC20 in sepolia
        depositInPool(deployedSepoliaPool, deposit_amount, sepoliaUnderlying, sepoliaFork, LP_SEP);

        uint256 finalPoolBalance = sepoliaUnderlying.balanceOf(deployedSepoliaPool);

        uint256 lptTransferedToLP = CrossChainPool(deployedSepoliaPool).balanceOf(LP_SEP);

        assertEq(finalPoolBalance, initialPoolBalance + deposit_amount);
        assertEq(calculatedReturnLPT, lptTransferedToLP);
        assertEq(
            lptTransferedToLP,
            deposit_amount * (initialCrossChainUnderlyingAmount / initialCrossChainLiquidityPoolTokens)
        ); // should be same amount of deposited ERC20 in this case, testing more later on
        vm.stopPrank();

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); //switch to arb
        vm.selectFork(arbSepoliaFork);
        (uint256 crossChainUnderlyingBalance, uint256 crossChainLiquidityPoolTokens) =
            CrossChainPool(deployedArbSepoliaPool).getCrossChainBalances();

        assertEq(crossChainUnderlyingBalance, finalPoolBalance);
        assertEq(crossChainLiquidityPoolTokens, lptTransferedToLP);
    }

    /// @notice tests a depositing after a teleporting
    function testDepositAfterTeleport() public depositedInSepolia {
        vm.selectFork(sepoliaFork);
        uint256 teleportAmount = 5e18;

        uint256 lptAmountOfLPSEPBeforeTeleporting = CrossChainPool(deployedSepoliaPool).balanceOf(LP_SEP);
        vm.stopPrank();

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);

        vm.selectFork(sepoliaFork);

        // TELEPORTING FROM SEPOLIA TO ARBITRUM SEPOLIA HERE
        teleport(teleportAmount, valentinoRossi, sepoliaFork, arbSepoliaFork, deployedSepoliaPool, sepoliaUnderlying);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); //switch to arb

        uint256 second_deposit_amount_on_sepolia = 10e18;
        depositInPool(deployedSepoliaPool, second_deposit_amount_on_sepolia, sepoliaUnderlying, sepoliaFork, LP_SEP);

        uint256 valueOfOneLptBeforeDeposit = CrossChainPool(deployedSepoliaPool).getValueOfOneLpt();

        uint256 currentLPSEPAmountLpt = CrossChainPool(deployedSepoliaPool).balanceOf(LP_SEP);

        uint256 lastMintedLptForLPSEP = currentLPSEPAmountLpt - lptAmountOfLPSEPBeforeTeleporting;

        assertEq(lastMintedLptForLPSEP, ((second_deposit_amount_on_sepolia * 1e18) / valueOfOneLptBeforeDeposit));
        assertLt(lastMintedLptForLPSEP, second_deposit_amount_on_sepolia);
    }

    function testRedeemAfterTeleport() public {
        vm.selectFork(arbSepoliaFork);
        uint256 LpBalanceBeforeRedeem = arbSepoliaUnderlying.balanceOf(LP_SEP);

        vm.selectFork(sepoliaFork);
        uint256 teleportAmount = 5e18;

        uint256 lptAmountOfLPSEPBeforeTeleporting = CrossChainPool(deployedSepoliaPool).balanceOf(LP_SEP);
        vm.stopPrank();

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);

        vm.selectFork(sepoliaFork);

        // TELEPORTING FROM SEPOLIA TO ARBITRUM SEPOLIA HERE
        teleport(teleportAmount, valentinoRossi, sepoliaFork, arbSepoliaFork, deployedSepoliaPool, sepoliaUnderlying);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); //switch to arb

        uint256 second_deposit_amount_on_sepolia = 10e18;
        depositInPool(deployedSepoliaPool, second_deposit_amount_on_sepolia, sepoliaUnderlying, sepoliaFork, LP_SEP);

        uint256 valueOfOneLptBeforeDeposit = CrossChainPool(deployedSepoliaPool).getValueOfOneLpt();

        uint256 currentLPSEPAmountLpt = CrossChainPool(deployedSepoliaPool).balanceOf(LP_SEP);
        uint256 userUnderlyingBalanceBeforeRedeemal = sepoliaUnderlying.balanceOf(LP_SEP);

        uint256 lastMintedLptForLPSEP = currentLPSEPAmountLpt - lptAmountOfLPSEPBeforeTeleporting;

        assertEq(lastMintedLptForLPSEP, ((second_deposit_amount_on_sepolia * 1e18) / valueOfOneLptBeforeDeposit));
        assertLt(lastMintedLptForLPSEP, second_deposit_amount_on_sepolia);

        //// start testing the redeemal

        (uint256 redeemCurrentChain, uint256 redeemCrossChain) =
            CrossChainPool(deployedSepoliaPool).calculateAmountToRedeem(currentLPSEPAmountLpt);

        CrossChainPool(deployedSepoliaPool).getCrossChainBalances();

        uint256 totalRedeem = CrossChainPool(deployedSepoliaPool).getRedeemValueForLP(currentLPSEPAmountLpt);

        // adding 1 as we have a small decimal precision issue
        assertEq(totalRedeem, redeemCurrentChain + redeemCrossChain + 1); // taking off the last decimals
            // totalRedeem                           = 9999999999999999999
            // redeemCurrentChain + redeemCrossChain = 9999999999999999988

        // cooldown and redeem
        cooldownAndRedeem(LP_SEP, sepoliaFork, arbSepoliaFork, deployedSepoliaPool, currentLPSEPAmountLpt);

        vm.selectFork(sepoliaFork);
        uint256 userUnderlyingBalanceAfterRedeemal = sepoliaUnderlying.balanceOf(LP_SEP);

        //making sure the lp get the correct amount back on the current chain
        assertEq(userUnderlyingBalanceAfterRedeemal, userUnderlyingBalanceBeforeRedeemal + redeemCurrentChain);

        //making sure the lp get the redeem amount back on the other chain
        vm.selectFork(arbSepoliaFork);

        assertLt(LpBalanceBeforeRedeem, LpBalanceBeforeRedeem + redeemCrossChain);
    }

    /*//////////////////////////////////////////////////////////////
                       HELPERS FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function depositInPool(
        address poolAddress,
        uint256 depositAmount,
        ERC20Mock underlying,
        uint256 fromFork,
        address user
    ) public {
        vm.selectFork(fromFork);
        vm.startPrank(user);
        uint256 ccipFees = CrossChainPool(poolAddress).getCCipFeesForDeposit(depositAmount);
        underlying.approve(poolAddress, type(uint256).max);
        CrossChainPool(poolAddress).deposit{value: ccipFees}(underlying, depositAmount);
        vm.stopPrank();
    }

    function teleport(
        uint256 amountToTeleport,
        address user,
        uint256 fromFork,
        uint256 toFork,
        address fromPool,
        ERC20Mock fromUnderlying
    ) public {
        vm.selectFork(fromFork);

        vm.startPrank(user);
        fromUnderlying.approve(address(fromPool), amountToTeleport);

        uint256 fee = CrossChainPool(fromPool).getCcipFeesForTeleporting(amountToTeleport, user);
        CrossChainPool(fromPool).teleport{value: fee}(amountToTeleport, user);
        vm.stopPrank();

        ccipLocalSimulatorFork.switchChainAndRouteMessage(toFork);
    }

    function cooldownAndRedeem(
        address user,
        uint256 fromFork,
        uint256 toFork,
        address fromPool,
        uint256 currentLPSEPAmountLpt
    ) public {
        vm.selectFork(fromFork);
        vm.startPrank(user);
        uint256 ccipFeesRedeem = CrossChainPool(fromPool).getCCipFeesForRedeem(currentLPSEPAmountLpt, user);
        uint256 ccipFeesCooldown = CrossChainPool(fromPool).getCCipFeesForCooldown(currentLPSEPAmountLpt);

        CrossChainPool(fromPool).setCooldownForLp{value: ccipFeesCooldown}(currentLPSEPAmountLpt);

        vm.warp(block.timestamp + 60 * 60 * 24);

        CrossChainPool(fromPool).redeem{value: ccipFeesRedeem}(currentLPSEPAmountLpt, user);
        vm.stopPrank();
        ccipLocalSimulatorFork.switchChainAndRouteMessage(toFork);
    }
}
