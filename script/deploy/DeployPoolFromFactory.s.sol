// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {CrossChainPool} from "../../src/CrossChainPool.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";

// todo update it with real pks
contract DeployPoolFromFactory is Script {
    function deploy(
        address factoryAddress,
        address _receiverFactory,
        address _underlyingTokenOnSourceChain,
        address _underlyingTokenOnDestinationChain,
        uint64 _destinationChainSelector,
        string memory _poolName
    ) public returns (address crossChainPool) {
        PoolFactory poolFactory = PoolFactory(factoryAddress);
        vm.startBroadcast();
        // crossChainPool = poolFactory.deployCCPools(
        //     _receiverFactory,
        //     _underlyingTokenOnSourceChain,
        //     _underlyingTokenOnDestinationChain,
        //     _destinationChainSelector,
        //     _poolName
        // );
        crossChainPool = poolFactory.deployCCPoolsCreate2(
            _receiverFactory,
            _underlyingTokenOnSourceChain,
            _underlyingTokenOnDestinationChain,
            _destinationChainSelector,
            _poolName
        );
        vm.stopBroadcast();
    }
}
