// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter} from "./library/PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 public minUsd = 5e18;
    address chainlinkAggregatorV3InterfaceAddressEthUsd =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public fundOwner;

    constructor() {
        fundOwner = msg.sender;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate() >= minUsd,
            "didn't send enough ETH"
        );

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
        require(callSuccess, "Call failed!!!!!");
    }

    /* 
        -----------------------------------------------
        ------------------ modifiers ------------------
        -----------------------------------------------
        - modifiers allows us to create keywords, that we can easily use in our functions
        - in our example, we have created a modifier to use with the functions that should only be called by the owner
        - (_;) this underscore semicolon, tells the modifier the rest of the code should go here
        - we also could place it (_;) above the require call, in that case all the code in the function would execute first then the require line
    */
    modifier onlyOwner() {
        require(
            msg.sender == fundOwner,
            "You are not authorized to withdraw the fund!"
        );
        _;
    }
}
