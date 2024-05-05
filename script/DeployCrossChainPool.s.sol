// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {CrossChainPool} from "../src/CrossChainPool.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// todo update it with real pks
contract DeployCrossChainPool is Script {
    ERC20Mock public underlying;

    function run() public returns (CrossChainPool) {
        underlying = new ERC20Mock();
        CrossChainPool crossChainPool = new CrossChainPool(underlying, "crossChainPoolTest");
        return crossChainPool;
    }
}
