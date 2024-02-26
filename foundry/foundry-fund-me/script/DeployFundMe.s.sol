// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast -> Not a "real" tx
        // we don't need our helper config to be a "real" tx
        HelperConfig helperConfig = new HelperConfig();
        /*  
            usually when destructuring a struct, we need to do something like:
            (address priceFeed, uint256 version) = helperConfig.activeNetworkConfig();
            but as for now we only have one field in the struct, we can directly access it
        */
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        // After stopBroadcast -> "real" tx
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
