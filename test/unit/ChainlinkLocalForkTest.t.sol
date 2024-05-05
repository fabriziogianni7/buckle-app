// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25; // up to

import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

contract Demo is CCIPLocalSimulatorFork {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;

    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    function setUp() public {
        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        string memory ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
        sepoliaFork = vm.createSelectFork(ETHEREUM_SEPOLIA_RPC_URL);
        arbSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));
    }

    function testDemo() public {
        sender.transferTokensPayLINK(arbSepoliaChainSelector, alice, address(ccipBnM), amountToSend);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork);
    }
}
