// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {PoolFactory} from "../src/PoolFactory.sol";
import {Config} from "./helper/Config.sol";
import {Register} from "../test/unit/helpers/Register.sol";

// todo update it with real pks
contract DeployPoolFactory is Script {
    Config public config;
    Register.NetworkDetails public activeConfig;

    function run() public returns (PoolFactory) {
        config = new Config();
        activeConfig = config.getActiveNetworkConfig();
        vm.startBroadcast();
        PoolFactory poolFactory = new PoolFactory(activeConfig.routerAddress, activeConfig.linkAddress);
        vm.stopBroadcast();
        return poolFactory;
    }
}
