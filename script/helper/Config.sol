// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "forge-std/Script.sol";
import {Register} from "../../test/unit/helpers/Register.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockRouter} from "../../test/unit/mock/MockRouter.sol";

contract Config is Script {
    Register public register;
    Register.NetworkDetails public activeConfig;

    constructor() {
        register = new Register();
        if (block.chainid == 31337) {
            ERC20Mock eRC20Mock = new ERC20Mock();
            Register.NetworkDetails memory anvilDetails = Register.NetworkDetails({
                chainSelector: 1,
                routerAddress: address(new MockRouter()),
                linkAddress: address(eRC20Mock),
                wrappedNativeAddress: address(0),
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0)
            });
            eRC20Mock.mint(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38, 100e18);
            register.setNetworkDetails(31337, anvilDetails);
        }
        activeConfig = register.getNetworkDetails(block.chainid);
    }

    function getActiveNetworkConfig() public view returns (Register.NetworkDetails memory) {
        return activeConfig;
    }
}