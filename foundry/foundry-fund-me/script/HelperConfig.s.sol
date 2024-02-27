// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/* 
    1. Deploy mocks when we are on a local envil network / chain
    2. Keep track of different contract addresses across different networks / chains
        For eg:
            - Sepolia ETH/USD
            - Mainnet ETH/USD 
*/

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    /*  
        - if we are on a local envil network, we want to deploy mocks
        - otherwise, grab the existing addresses from the live network
    */

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        // every network has a unique chainid
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 5777) {
            activeNetworkConfig = getOrCreateGanacheEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
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

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // with this we will check if we have already deployed the mock
        // if we have already deployed the mock, we don't need to deploy it again
        // we can just return the address of the mock
        // address(0) is the default value for an address
        // it's like saying:
        // address = null
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        /* 
            This is going to be a little different
            1. Deploy the mocks
            2. Return the mock address 
        */

        // and since we are using this vm keyword, we can't use the pure keyword
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }

    // similar to the getOrCreateAnvilEthConfig function
    function getOrCreateGanacheEthConfig()
        public
        returns (NetworkConfig memory)
    {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
