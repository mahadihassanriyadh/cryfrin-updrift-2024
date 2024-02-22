// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    uint256 public minUsd = 5e18;
    address chainlinkAggregatorV3InterfaceAddressEthUsd =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        require(
            getConversionRate(msg.value) >= minUsd,
            "didn't send enough ETH"
        );

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] =
            addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            chainlinkAggregatorV3InterfaceAddressEthUsd
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        if (answer < 0) {
            revert("Negative price not supported");
        }
        return uint256(answer * 1e10);
    }

    function getConversionRate(uint256 ethAmmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmmountInUSD = (ethPrice * ethAmmount) / 1e18;

        return ethAmmountInUSD;
    }

    function getVersion() public view returns (uint256) {
        return
            AggregatorV3Interface(chainlinkAggregatorV3InterfaceAddressEthUsd)
                .version();
    }

    function withdraw() public {}
}
