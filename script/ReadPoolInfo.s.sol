// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {CrossChainPool} from "../src/CrossChainPool.sol";
import {PoolFactory} from "../src/PoolFactory.sol";

// todo update it with real pks
/**
 * forge script script/ReadPoolInfo.s.sol:ReadPoolInfo  --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --account deployer --sender 0xB9f26cFfC3Cda860035E2183DAEa7daD8f266bc3 -vvvvv --sig "read(address)" 0x28f7c1e6a8f56729cb1d541ff6ddd934636343bf
 */
contract ReadPoolInfo is Script {
    function read(address addr) public view {
        CrossChainPool pool = CrossChainPool(addr);
        (address s_crossChainPool, uint64 i_crossChainSelector) = pool.getCrossChainSenderAndSelector();
        console2.log("s_crossChainPool", s_crossChainPool);
        console2.log("i_crossChainSelector", i_crossChainSelector);
    }
}
