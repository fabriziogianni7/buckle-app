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

    uint64 sepoliaChainSelector = 16015286601757825753;
    uint64 arbSepoliaChainSelector = 3478487238524512106;

    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    PoolFactory public arbFactory;
    PoolFactory public sepoliaFactory;

    address poolDeployer = address(4);
    address valentinoRossi = address(46);
    address LP = address(102);

    address deployedSepoliaPool;
    address deployedArbSepoliaPool;

    ERC20Mock public sepoliaUnderlying;
    ERC20Mock public arbSepoliaUnderlying;

    uint256 ERC20_MINT_AMOUNT = 10e18;

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
        sepoliaUnderlying.mint(valentinoRossi, ERC20_MINT_AMOUNT);

        // deploy factory on 1st chain (sepolia)

        address routerAddressSepolia = ccipLocalSimulatorFork.getNetworkDetails(block.chainid).routerAddress;

        address feeTokenSepolia = ccipLocalSimulatorFork.getNetworkDetails(block.chainid).linkAddress;

        DeployPoolFactory deployPoolFactorySep = new DeployPoolFactory();

        sepoliaFactory = deployPoolFactorySep.run(routerAddressSepolia, feeTokenSepolia);

        ccipLocalSimulatorFork.requestLinkFromFaucet(address(sepoliaFactory), 100e18);

        ////// ARBITRUM SEPOLIA //////
        //creating a new ERC20 for testing
        vm.selectFork(arbSepoliaFork);
        vm.deal(LP, 1000 ether);
        arbSepoliaUnderlying = new ERC20Mock();
        arbSepoliaUnderlying.mint(LP, ERC20_MINT_AMOUNT + 100e18);

        // deploy factory on 2nd chain (arb-sepolia)

        address routerAddressArb = ccipLocalSimulatorFork.getNetworkDetails(block.chainid).routerAddress;

        address feeTokenArb = ccipLocalSimulatorFork.getNetworkDetails(block.chainid).linkAddress;

        DeployPoolFactory deployPoolFactoryArb = new DeployPoolFactory();

        arbFactory = deployPoolFactoryArb.run(routerAddressArb, feeTokenArb);

        ccipLocalSimulatorFork.requestLinkFromFaucet(address(arbFactory), 100e18);

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
        vm.startPrank(LP);
        arbSepoliaUnderlying.approve(deployedArbSepoliaPool, type(uint256).max);
        CrossChainPool(deployedArbSepoliaPool).deposit(arbSepoliaUnderlying, 10e18);

        vm.selectFork(sepoliaFork);
        assertNotEq(sepoliaFactory.getALlDeployedPoolsForChainSelector(destinationChainSelector)[0], address(0));
    }

    function testForkIsOk() public {
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

        uint256 fee = CrossChainPool(deployedSepoliaPool).getFeesForTeleporting(TELEPORT_AMOUNT, valentinoRossi);
        CrossChainPool(deployedSepoliaPool).startTeleport{value: fee}(TELEPORT_AMOUNT, valentinoRossi);

        assertEq(sepoliaUnderlying.balanceOf(address(deployedSepoliaPool)), TELEPORT_AMOUNT);
        vm.stopPrank();

        console2.log("arbSepoliaUnderlying", address(arbSepoliaUnderlying));
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);
        // vm.selectFork(arbSepoliaFork);

        assertEq(arbSepoliaUnderlying.balanceOf(valentinoRossi), TELEPORT_AMOUNT);
    }
}
