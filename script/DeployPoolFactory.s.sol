// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {PoolFactory} from "../src/PoolFactory.sol";

// todo update it with real pks
contract DeployPoolFactory is Script {
    function run(address router, address feeToken) public returns (PoolFactory) {
        PoolFactory poolFactory = new PoolFactory(router, feeToken);
        return poolFactory;
    }
}
