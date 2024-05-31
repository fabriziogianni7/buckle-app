// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "ccip/contracts/ccip/libraries/Client.sol";

contract MockRouter {
    error OnlyOffRamp();

    /// @notice mock contract for local dummy tests
    function routeMessage(
        Client.Any2EVMMessage calldata,
        /**
         * message
         */
        uint16,
        /**
         * gasForCallExactCheck
         */
        uint256,
        /**
         * gasLimit
         */
        address
    )
        /**
         * receiver
         */
        external
        pure
        returns (bool success, bytes memory retBytes, uint256 gasUsed)
    {
        success = true;
        retBytes = "";
        gasUsed = 1;
    }

    function getFee(
        uint64,
        /**
         * xchainselector
         */
        Client.EVM2AnyMessage memory /*message*/
    ) public pure returns (uint256 fee) {
        fee = 1;
    }

    function ccipSend(
        uint64,
        /**
         * xchainselector
         */
        Client.EVM2AnyMessage memory
    )
        /**
         * message
         */
        public
        payable
        returns (bytes32 id)
    {
        id = "";
    }
}
