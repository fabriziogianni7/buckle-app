// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {CrossChainPool} from "../src/CrossChainPool.sol";

// todo update it with real pks
contract DeployCrossChainPool is Script {
    function run(address currentChainUnderlying, address crossChainUnderlying, address mockRouter)
        public
        returns (CrossChainPool)
    {
        CrossChainPool crossChainPool =
            new CrossChainPool(currentChainUnderlying, "crossChainPoolTest", 1, mockRouter, crossChainUnderlying);
        return crossChainPool;
    }
}
