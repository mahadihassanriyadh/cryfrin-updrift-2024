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

    /* 
        Withdrawing money issue
        - we want anyone to fund the contract
        - but we do not want anyone to just withdraw the money
        - so we need to set a owner of the contract
        - we could create a function like callMeRightAway(), and when we deploy the contract, we would just immediately call the call this function which would make us the owner
        - but this is not an efficient approach, as this would result in two transactions, which is equal to more gas
        - that is why we will use constructor here  
    */
    /* 
        --------------------------------------------------
        -------------- Solidity Constructor --------------
        --------------------------------------------------
        - this is similar to contructor in any other language
        - whenever we deploy this contract, the constructor would be called right away
        - doing the whole thing in one transaction
    */
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

    function withdraw() public {

        require(msg.sender == fundOwner, "You are not authorized to withdraw the fund!");

        for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
            address funder = funders[funderIdx];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed!!!!!");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!!!!!");
    }
}
