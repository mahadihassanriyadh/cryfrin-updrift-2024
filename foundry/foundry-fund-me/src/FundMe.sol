// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter} from "./PriceConverter.sol";

error DidNotSendMinEth();
error NotFundOwner();
error FundTransferFailed();

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
            revert DidNotSendMinEth();
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
            revert FundTransferFailed();
        }
    }

    modifier onlyOwner() {
        if (msg.sender != i_fundOwner) {
            revert NotFundOwner();
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
