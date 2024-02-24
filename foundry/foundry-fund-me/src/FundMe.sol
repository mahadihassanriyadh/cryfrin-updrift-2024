// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// it's a convention to add the contract name before the error so that it's easier for us to understand where the error is coming from
error FundMe__DidNotSendMinEth();
error FundMe__NotFundOwner();
error FundMe__FundTransferFailed();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 5e18;

    bytes32 public testFallbackTrigger =
        0x746573744e756d00000000000000000000000000000000000000000000000000;
    int256 public testFallbackVar = 0;

    address chainlinkAggregatorV3InterfaceAddressEthUsd =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_fundOwner;

    constructor() {
        i_fundOwner = msg.sender;
    }

    function fund() public payable {
        if (msg.value.getConversionRate() < MIN_USD) {
            revert FundMe__DidNotSendMinEth();
        }
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
            address funder = funders[funderIdx];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!callSuccess) {
            revert FundMe__FundTransferFailed();
        }
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            chainlinkAggregatorV3InterfaceAddressEthUsd
        );
        return priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != i_fundOwner) {
            revert FundMe__NotFundOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
        if (bytes32(msg.data) == testFallbackTrigger) {
            testFallbackVar += 1;
        }
    }
}
