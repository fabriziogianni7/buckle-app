// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {PoolFactory} from "../src/PoolFactory.sol";
import {Config} from "./helper/Config.sol";
import {Register} from "../test/unit/helpers/Register.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// todo update it with real pks
contract DeployPoolFactory is Script {
    Config public config;
    Register.NetworkDetails public activeConfig;
    uint256 public FEE_TOKEN_DEPOSIT_AMOUNT = 5e18;

    function run() public returns (PoolFactory) {
        config = new Config();
        activeConfig = config.getActiveNetworkConfig();
        vm.startBroadcast();
        PoolFactory poolFactory = new PoolFactory(activeConfig.routerAddress, activeConfig.linkAddress);
        IERC20(activeConfig.linkAddress).approve(address(poolFactory), FEE_TOKEN_DEPOSIT_AMOUNT);
        poolFactory.depositFeeToken(FEE_TOKEN_DEPOSIT_AMOUNT);
        vm.stopBroadcast();
        return poolFactory;
    }
}
