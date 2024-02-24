// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        if (answer < 0) {
            revert("Negative price not supported");
        }
        return uint256(answer * 1e10);
    }

    function getConversionRate(
        uint256 ethAmmount
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmmountInUSD = (ethPrice * ethAmmount) / 1e18;

        return ethAmmountInUSD;
    }
}
