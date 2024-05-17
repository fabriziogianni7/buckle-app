// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {PoolFactory} from "../src/PoolFactory.sol";

// todo update it with real pks
/**
 * forge script script/RedeemLink.s.sol:RedeemLink  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvvv --sig "redeem(address)" 0x40ed5256EC8E69D2E9bc4781c27e5b833589Dc0f
 */
contract RedeemLink is Script {
    function redeem(address addr) public {
        PoolFactory factory = PoolFactory(addr);
        vm.startBroadcast();
        factory.withdrawFeeToken();
        vm.stopBroadcast();
    }
}
