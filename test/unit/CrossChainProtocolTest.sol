// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25; // up to

import {Test, console2} from "forge-std/Test.sol";
import {Register} from "./helpers/Register.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {DeployPoolFactory} from "../../script/DeployPoolFactory.s.sol";
import {CrossChainPool} from "../../src/CrossChainPool.sol";
import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract CrossChainProtocolTest is Test {
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
    uint256 public INITIAL_DEPOSIT_ARB_LP_SEPOLIA = 15e18;

    // 1. deploy factories on 2 networks ok
    // 2. call deployCCPools ok

    function setUp() public {
        sepoliaFork = vm.createSelectFork(vm.rpcUrl("sepolia"));
        arbSepoliaFork = vm.createFork(vm.rpcUrl("arbitrumSepolia"));

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

        // deploy factory on 1st chain (sepolia)

        address routerAddressSepolia = ccipLocalSimulatorFork.getNetworkDetails(block.chainid).routerAddress;

        address feeTokenSepolia = ccipLocalSimulatorFork.getNetworkDetails(block.chainid).linkAddress;

        ccipLocalSimulatorFork.requestLinkFromFaucet(DEPLOYER, 100e18);

        vm.startPrank(DEPLOYER);

        DeployPoolFactory deployPoolFactorySep = new DeployPoolFactory();

        sepoliaFactory = deployPoolFactorySep.run();
        vm.stopPrank();

        ////// ARBITRUM SEPOLIA //////
        //creating a new ERC20 for testing
        vm.selectFork(arbSepoliaFork);
        vm.deal(LP_ARB, 1000 ether);
        arbSepoliaUnderlying = new ERC20Mock();
        arbSepoliaUnderlying.mint(LP_ARB, ERC20_MINT_AMOUNT + 10000e18);

        // deploy factory on 2nd chain (arb-sepolia)

        address routerAddressArb = ccipLocalSimulatorFork.getNetworkDetails(block.chainid).routerAddress;

        address feeTokenArb = ccipLocalSimulatorFork.getNetworkDetails(block.chainid).linkAddress;

        vm.startPrank(DEPLOYER);
        ccipLocalSimulatorFork.requestLinkFromFaucet(DEPLOYER, 100e18);

        DeployPoolFactory deployPoolFactoryArb = new DeployPoolFactory();

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

        vm.startPrank(LP_ARB);

        uint256 ccipFees = CrossChainPool(deployedArbSepoliaPool).getCCipFeesForDeposit(INITIAL_DEPOSIT_ARB_LP_SEPOLIA);
        arbSepoliaUnderlying.approve(deployedArbSepoliaPool, type(uint256).max);
        CrossChainPool(deployedArbSepoliaPool).deposit{value: ccipFees}(
            arbSepoliaUnderlying, INITIAL_DEPOSIT_ARB_LP_SEPOLIA
        );

        ccipLocalSimulatorFork.switchChainAndRouteMessage(sepoliaFork); // here on sepolia
        (uint256 underlyingAmount,) = CrossChainPool(deployedSepoliaPool).getCrossChainBalances();
        vm.stopPrank();
        assertEq(underlyingAmount, INITIAL_DEPOSIT_ARB_LP_SEPOLIA);
        vm.selectFork(sepoliaFork);
        assertNotEq(sepoliaFactory.getALlDeployedPoolsForChainSelector(destinationChainSelector)[0], address(0));
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

    function testTeleporting() public {
        uint256 TELEPORT_AMOUNT = 5e18;
        // user need to deposit ERC20 in sepolia
        vm.selectFork(sepoliaFork);

        vm.startPrank(valentinoRossi);
        sepoliaUnderlying.approve(address(deployedSepoliaPool), TELEPORT_AMOUNT);

        uint256 fee = CrossChainPool(deployedSepoliaPool).getCcipFeesForTeleporting(TELEPORT_AMOUNT, valentinoRossi);
        CrossChainPool(deployedSepoliaPool).teleport{value: fee}(TELEPORT_AMOUNT, valentinoRossi);
        assertEq(sepoliaUnderlying.balanceOf(address(deployedSepoliaPool)), TELEPORT_AMOUNT);
        vm.stopPrank();

        uint256 buckleAppFees = CrossChainPool(deployedSepoliaPool).calculateBuckleAppFees(TELEPORT_AMOUNT);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);

        assertEq(arbSepoliaUnderlying.balanceOf(valentinoRossi), TELEPORT_AMOUNT - buckleAppFees);
    }

    function testCrossChainDeposit() public {
        vm.selectFork(sepoliaFork);
        uint256 deposit_amount = 5e18;

        (uint256 initialCrossChainUnderlyingAmount, uint256 initialCrossChainLiquidityPoolTokens) =
            CrossChainPool(deployedSepoliaPool).getCrossChainBalances();

        uint256 calculatedReturnLPT =
            CrossChainPool(deployedSepoliaPool).calculateLPTinExchangeOfUnderlying(deposit_amount);

        uint256 initialPoolBalance = sepoliaUnderlying.balanceOf(deployedSepoliaPool);
        // user need to deposit ERC20 in sepolia
        vm.startPrank(LP_SEP);
        sepoliaUnderlying.approve(address(deployedSepoliaPool), type(uint256).max);

        uint256 ccipFees = CrossChainPool(deployedSepoliaPool).getCCipFeesForDeposit(deposit_amount);

        CrossChainPool(deployedSepoliaPool).deposit{value: ccipFees}(sepoliaUnderlying, deposit_amount);

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
        (uint256 crossChainUnderlyingBalance, uint256 crossChainLiquidityPoolTokens) =
            CrossChainPool(deployedArbSepoliaPool).getCrossChainBalances();

        assertEq(crossChainUnderlyingBalance, finalPoolBalance);
        assertEq(crossChainLiquidityPoolTokens, lptTransferedToLP);
    }

    function testCrossChainDepositAfterTeleport() public {
        vm.selectFork(sepoliaFork);
        uint256 deposit_amount = 5e18;
        uint256 teleportAmount = 5e18;

        // user need to deposit ERC20 in sepolia
        vm.startPrank(LP_SEP);
        sepoliaUnderlying.approve(address(deployedSepoliaPool), type(uint256).max);

        uint256 ccipFees1 = CrossChainPool(deployedSepoliaPool).getCCipFeesForDeposit(deposit_amount);

        CrossChainPool(deployedSepoliaPool).deposit{value: ccipFees1}(sepoliaUnderlying, deposit_amount);

        uint256 lptAmountOfLPSEPBeforeTeleporting = CrossChainPool(deployedSepoliaPool).balanceOf(LP_SEP);
        vm.stopPrank();

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);

        vm.selectFork(sepoliaFork);

        // TELEPORTING HERE
        vm.startPrank(valentinoRossi);

        sepoliaUnderlying.approve(address(deployedSepoliaPool), teleportAmount);

        uint256 ccipFees2 =
            CrossChainPool(deployedSepoliaPool).getCcipFeesForTeleporting(teleportAmount, valentinoRossi);

        CrossChainPool(deployedSepoliaPool).teleport{value: ccipFees2}(teleportAmount, valentinoRossi);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); //switch to arb

        // LPT : UDT 1:1
        // 0.whatever : 1
        vm.selectFork(sepoliaFork);
        uint256 second_deposit_amount_on_sepolia = 10e18;

        vm.startPrank(LP_SEP);

        uint256 valueOfOneLptBeforeDeposit = CrossChainPool(deployedSepoliaPool).getValueOfOneLpt();

        sepoliaUnderlying.approve(address(deployedSepoliaPool), type(uint256).max);

        uint256 ccipFees3 = CrossChainPool(deployedSepoliaPool).getCCipFeesForDeposit(second_deposit_amount_on_sepolia);

        CrossChainPool(deployedSepoliaPool).deposit{value: ccipFees3}(
            sepoliaUnderlying, second_deposit_amount_on_sepolia
        );

        uint256 currentLPSEPAmountLpt = CrossChainPool(deployedSepoliaPool).balanceOf(LP_SEP);

        uint256 lastMintedLptForLPSEP = currentLPSEPAmountLpt - lptAmountOfLPSEPBeforeTeleporting;
        console2.log("lastMintedLptForLPSEP", lastMintedLptForLPSEP);
        console2.log(
            "second_deposit_amount_on_sepolia / valueOfOneLptBeforeDeposit",
            ((second_deposit_amount_on_sepolia * 1e18) / valueOfOneLptBeforeDeposit)
        );
        // 9987510000000000000
        // 9987515600000000000
        console2.log("second_deposit_amount_on_sepolia", second_deposit_amount_on_sepolia);

        assertEq(lastMintedLptForLPSEP, ((second_deposit_amount_on_sepolia * 1e18) / valueOfOneLptBeforeDeposit));
        assertLt(lastMintedLptForLPSEP, second_deposit_amount_on_sepolia);
    }

    function testCrossChainRedeemAfterTeleport() public {
        vm.selectFork(sepoliaFork);
        uint256 deposit_amount = 5e18;

        // LP need to deposit ERC20 in sepolia
        vm.startPrank(LP_SEP);
        sepoliaUnderlying.approve(address(deployedSepoliaPool), type(uint256).max);

        uint256 ccipFees1 = CrossChainPool(deployedSepoliaPool).getCCipFeesForDeposit(deposit_amount);

        CrossChainPool(deployedSepoliaPool).deposit{value: ccipFees1}(sepoliaUnderlying, deposit_amount);
        vm.stopPrank();

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);

        vm.selectFork(sepoliaFork);

        // TELEPORTING HERE
        vm.startPrank(valentinoRossi);

        uint256 teleportAmount = 1e18;
        sepoliaUnderlying.approve(address(deployedSepoliaPool), teleportAmount);

        uint256 ccipFees2 =
            CrossChainPool(deployedSepoliaPool).getCcipFeesForTeleporting(teleportAmount, valentinoRossi);

        CrossChainPool(deployedSepoliaPool).teleport{value: ccipFees2}(teleportAmount, valentinoRossi);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); //switch to arb

        // LPT : UDT 1:1
        // 0.whatever : 1
        vm.selectFork(sepoliaFork);
        uint256 second_deposit_amount_on_sepolia = 10e18;

        vm.startPrank(LP_SEP);

        sepoliaUnderlying.approve(address(deployedSepoliaPool), type(uint256).max);

        uint256 ccipFees3 = CrossChainPool(deployedSepoliaPool).getCCipFeesForDeposit(second_deposit_amount_on_sepolia);

        CrossChainPool(deployedSepoliaPool).deposit{value: ccipFees3}(
            sepoliaUnderlying, second_deposit_amount_on_sepolia
        );

        //// start testing the redeemal
        uint256 currentLPSEPAmountLpt = CrossChainPool(deployedSepoliaPool).balanceOf(LP_SEP);

        (uint256 redeemCurrentChain, uint256 redeemCrossChain) =
            CrossChainPool(deployedSepoliaPool).calculateAmountToRedeem(currentLPSEPAmountLpt);

        CrossChainPool(deployedSepoliaPool).getCrossChainBalances();

        uint256 totalRedeem = CrossChainPool(deployedSepoliaPool).getRedeemValueForLP(currentLPSEPAmountLpt);

        // assertEq(totalRedeem / 1e10, (redeemCurrentChain + redeemCrossChain) / 1e10); // it should definitelly be more precise, todo look into it
        // (totalRedeem / 1e2) =150012499999999999
        assertEq((totalRedeem / 1e2), (redeemCurrentChain + redeemCrossChain) / 1e2); // taking off the last decimals

        uint256 ccipFeesRedeem = CrossChainPool(deployedSepoliaPool).getCCipFeesForRedeem(currentLPSEPAmountLpt, LP_SEP);

        // CrossChainPool(deployedSepoliaPool).deposit{value: ccipFeesRedeem}(
        //     sepoliaUnderlying, second_deposit_amount_on_sepolia
        // );
        CrossChainPool(deployedSepoliaPool).redeem{value: ccipFeesRedeem}(currentLPSEPAmountLpt, LP_SEP);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); //
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);
        //
    }
}
