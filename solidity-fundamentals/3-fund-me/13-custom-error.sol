// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter} from "./library/PriceConverter.sol";

/* 
    --------------------------------------------------
    ------------------ custom error ------------------
    --------------------------------------------------
    - till now we have used 
        require(msg.sender == i_fundOwner, "You are not authorized to withdraw the fund!");
        statements like this
    - what happens here is we have to store a string which will be sent when an error occus.
    - After solidity 0.8.4 we have a new way to handle error, which can save some gas
    - we can declare custom error like this
        error NotFundOwner();
    - we will declare this before our contract starts
    - now we will replace our require function with this
        if (msg.sender != i_fundOwner) {
            revert NotFundOwner();
        }

    - after changing all requires to custom error, our gas:
    - 7,97,358 -> 7,39,560
*/

error DidNotSendMinEth();
error NotFundOwner();
error FundTransferFailed();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 5e18;

    address chainlinkAggregatorV3InterfaceAddressEthUsd =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public i_fundOwner;

    constructor() {
        i_fundOwner = msg.sender;
    }

    function fund() public payable {
        // require(
        //     msg.value.getConversionRate() >= MIN_USD,
        //     "didn't send enough ETH"
        // );

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
        // require(callSuccess, "Call failed!!!!!");
        if (!callSuccess) {
            revert FundTransferFailed();
        }
    }

    modifier onlyOwner() {
        // require(
        //     msg.sender == i_fundOwner,
        //     "You are not authorized to withdraw the fund!"
        // );
        
        if (msg.sender != i_fundOwner) {
            revert NotFundOwner();
        }
        _;
    }
}
