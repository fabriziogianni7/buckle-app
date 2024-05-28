// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {IRouterClient, WETH9, LinkToken, BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {CCIPLocalSimulator} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
// import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

contract ChainlinkLocalHelper is Script {
    CCIPLocalSimulator public ccipLocalSimulator;

    uint64 public chainSelector;
    IRouterClient public sourceRouter;
    IRouterClient public destinationRouter;
    WETH9 public wrappedNative;
    LinkToken public linkToken;
    BurnMintERC677Helper public ccipBnM;
    BurnMintERC677Helper public ccipLnM;

    function run(address user) public {
        ccipLocalSimulator = new CCIPLocalSimulator();

        (chainSelector, sourceRouter, destinationRouter, wrappedNative, linkToken, ccipBnM, ccipLnM) =
            ccipLocalSimulator.configuration();

        ccipLocalSimulator.requestLinkFromFaucet(user, 1000e18);
    }

    function mintFeeTokens(address user) public {
        ccipLocalSimulator.requestLinkFromFaucet(user, 10000e18);
    }

    function logInfo() public view {
        console2.log("chainSelector %s", chainSelector);
        console2.log("sourceRouter %s", address(sourceRouter));
        console2.log("destinationRouter %s", address(destinationRouter));
        console2.log("wrappedNative %s", address(wrappedNative));
        console2.log("linkToken %s", address(linkToken));
        console2.log("ccipBnM %s", address(ccipBnM));
        console2.log("ccipLnM %s", address(ccipLnM));
    }
}
