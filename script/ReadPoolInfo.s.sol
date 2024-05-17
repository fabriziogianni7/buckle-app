// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {CrossChainPool} from "../src/CrossChainPool.sol";
import {PoolFactory} from "../src/PoolFactory.sol";

// todo update it with real pks
/**
 * forge script script/ReadPoolInfo.s.sol:ReadPoolInfo  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvvv --sig "read(address)" 0x94E65a9f65B9dC2bB3871113Cb2BD2f84bab433b
 */
contract ReadPoolInfo is Script {
    function read(address addr) public view {
        CrossChainPool pool = CrossChainPool(addr);
        (address s_crossChainPool, uint64 i_crossChainSelector) = pool.getCrossChainSenderAndSelector();
        console2.log("s_crossChainPool", s_crossChainPool);
        console2.log("i_crossChainSelector", i_crossChainSelector);
    }
}
