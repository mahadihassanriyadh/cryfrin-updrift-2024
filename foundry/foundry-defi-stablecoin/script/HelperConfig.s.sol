// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUsdPriceFeed; // weth is the ERC20 token for Ethereum
        address wbtcUsdPriceFeed; // wbtc is the ERC20 token for Bitcoin
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2500e8;
    int256 public constant BTC_USD_PRICE = 65000e8;
    uint256 public constant DEFAUT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    
    MockV3Aggregator anvilEthUsdPriceFeed;
    MockV3Aggregator anvilBtcUsdPriceFeed;
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliadEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliadEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();

        anvilEthUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);

        anvilBtcUsdPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock wbtcMock = new ERC20Mock("WBTC", "WBTC", msg.sender, 1000e8);

        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeed: address(anvilEthUsdPriceFeed),
            wbtcUsdPriceFeed: address(anvilBtcUsdPriceFeed),
            weth: address(wethMock),
            wbtc: address(wbtcMock),
            deployerKey: DEFAUT_ANVIL_KEY
        });
    }
}
