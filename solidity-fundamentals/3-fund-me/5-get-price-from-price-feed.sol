// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    uint256 public minUsd = 5;
    address chainlinkAggregatorV3InterfaceAddressEthUsd =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;

    function fund() public payable {
        // this msg.value is in Wei
        // so it has 18 decimal places, as 1 ETH = 1e18 Wei
        require(msg.value >= minUsd, "didn't send enough ETH");
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            chainlinkAggregatorV3InterfaceAddressEthUsd
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // this int256 answer will return the current priec of ETH/USD
        // it's int256 because the values can sometimes be in negative depedning on the price feed
        // price of 1 ETH in USD
        // but we will not get data in decimal here, rather something like this 292520000000 ($2,925.20)
        // but chainlink's contract also provide a function to get the num of decimals, for eth/usd it's 8
        // we can also check the num of decimals for the feed form here (https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#sepolia-testnet) if we click on Show more details
        // we know we get the msg.value in 18 decimal as the value is always in Wei but we are getting the price here in 8 decimal
        // so to match up we will multiply price with 1e10, adding those additional 10 decimal places
        // another thing is, our msg.value is in uint256 and our price is in int256, so we will do a Typecast here, and make the int256 into uint256

        if (answer < 0) {
            // Handle negative price (e.g., return an error code)
            // because converting a neg int256 to uint256 will not happen without data loss, or won't happen as intended
            revert("Negative price not supported");
        }
        return uint256(answer * 1e10);
    }

    function getVersion() public view returns (uint256) {
        return
            AggregatorV3Interface(chainlinkAggregatorV3InterfaceAddressEthUsd)
                .version();
    }

    function getConversionRate() public {}

    function withdraw() public {}
}
