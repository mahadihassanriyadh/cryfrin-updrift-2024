// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author Md. Mahadi Hassan Riyadh
 * @notice This library is used to check the Chainlink Oracle for stale data.
 * If the price is stale, the function will revert, and render the DSCEngine unusable - this is by design.
 * We want the DSCEngine to freeze if prices become stale.
 *
 * So, if the chainlink network explodes and you have a lot of money locked in the protocol, you are kind of screwed...
 */
library OracleLib {
    error OracleLib__StalePriceData();

    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(AggregatorV3Interface _priceFeed)
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = _priceFeed.latestRoundData();

        uint256 timeElapsed = block.timestamp - updatedAt;
        
        if (timeElapsed > TIMEOUT) {
            revert OracleLib__StalePriceData();
        }

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
