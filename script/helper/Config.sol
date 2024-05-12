// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "forge-std/Script.sol";
import {Register} from "../../test/unit/helpers/Register.sol";

contract Config is Script {
    Register public register;
    Register.NetworkDetails public activeConfig;

    constructor() {
        register = new Register();
        activeConfig = register.getNetworkDetails(block.chainid);
    }

    function getActiveNetworkConfig() public view returns (Register.NetworkDetails memory) {
        return activeConfig;
    }
}
