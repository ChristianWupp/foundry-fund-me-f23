// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperCongig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast -> Not a "real" tx
        HelperConfig helperConfig = new HelperConfig();
        // Since it's only one in the struct, it works without the (,,,)
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        // After Broadcat = Real TX
        vm.startBroadcast();
        // Mock contract
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
