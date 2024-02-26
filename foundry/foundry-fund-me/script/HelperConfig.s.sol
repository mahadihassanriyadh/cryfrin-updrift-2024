// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/* 
    1. Deploy mocks when we are on a local ganache network / chain
    2. Keep track of different contract addresses across different networks / chains
        For eg:
            - Sepolia ETH/USD
            - Mainnet ETH/USD 
*/

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    /*  
        - if we are on a local ganache network, we want to deploy mocks
        - otherwise, grab the existing addresses from the live network
    */

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        // every network has a unique chainid
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getGanaheEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address from chainlink sepolia pricefeed (https://docs.chain.link/data-feeds/price-feeds/addresses)
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address from chainlink mainnet pricefeed (https://docs.chain.link/data-feeds/price-feeds/addresses)
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return sepoliaConfig;
    }

    function getGanaheEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
    }
}
