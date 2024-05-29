// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "forge-std/Script.sol";
import {Script, VmSafe, console2} from "forge-std/Script.sol";

import {Register} from "../../test/helpers/Register.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockRouter} from "../../test/unit/mock/MockRouter.sol";
// import {MockVrfWrapper} from "../../helpers/MockVrfWrapper.sol";
// import {MockERC20Link} from "../../helpers/MockERC20Link.sol";
// import {MockLinkToken} from "@chainlink/contracts/mocks/MockLinkToken.sol";

contract Config is Script {
    Register public register;
    Register.NetworkDetails public activeConfig;
    address public activePriceFeed;
    address public activeVrf;

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
            register.setNetworkDetails(31337, anvilDetails);
            activePriceFeed = address(0);
            address mockWrapper = address(0);
            activeVrf = address(mockWrapper);
        }
        activeConfig = register.getNetworkDetails(block.chainid);

        if (block.chainid == 11155111) {
            activePriceFeed = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
            activeVrf = 0x195f15F2d49d693cE265b4fB0fdDbE15b1850Cc1;
        }
        if (block.chainid == 421614) {
            activePriceFeed = 0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298;
            activeVrf = 0x327B83F409E1D5f13985c6d0584420FA648f1F56;
        }
        if (block.chainid == 43113) {
            activePriceFeed = 0x34C4c526902d88a3Aa98DB8a9b802603EB1E3470;
            activeVrf = 0x327B83F409E1D5f13985c6d0584420FA648f1F56;
        }
        if (block.chainid == 80002) {
            activePriceFeed = 0x34C4c526902d88a3Aa98DB8a9b802603EB1E3470;
            activeVrf = 0x6e6c366a1cd1F92ba87Fd6f96F743B0e6c967Bf0;
        }
    }

    function getActiveNetworkConfig() public view returns (Register.NetworkDetails memory) {
        return activeConfig;
    }

    function getActivePriceFeed() public view returns (address) {
        return activePriceFeed;
    }

    function getActiveVrf() public view returns (address) {
        return activeVrf;
    }
}
