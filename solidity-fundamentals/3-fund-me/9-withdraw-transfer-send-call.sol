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

    function fund() public payable {
        require(
            msg.value.getConversionRate() >= minUsd,
            "didn't send enough ETH"
        );

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public {
        for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
            address funder = funders[funderIdx];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        /* 
            Sending or Withdrawing Funds (https://solidity-by-example.org/sending-ether/)
            There are 3 ways to send native blockchain currencies
            - transfer
            - send
            - call 
        */
        /*  
            ----------------------------------------
            --------------- transfer ---------------
            ----------------------------------------
            - msg.sender = address
            - typecasting with payable()
            - payable(msg.sender) = payable address
            - to send native currency to an address we must work with a payable address
            - transfer has a cap to 2300 gas, if the gas used is more it will throw an error and revert the transaction
        */
        payable(msg.sender).transfer(address(this).balance);

        /*  
            ------------------------------------
            --------------- send ---------------
            ------------------------------------
            - send also has a cap to 2300 gas, but instead of thworing error it will return a boolean value if it was successfull or not
        */
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed!!!!!");

        /*  
            ------------------------------------------------------------------
            --------------- call (Recommended Way to Send $$$) ---------------
            ------------------------------------------------------------------
            - call is the one of the first lower level commands that we actually use in our solidity code
            - this call function is increadibly powerful
            - we can use it to call virtually any function in all of Ethereum without even having to have the ABI
            - we will learn the advanced ways to use this call much later
            - for now we will just use it to send our native currency

            ------------------------------------------------------------------------

            - call() inside this call first brackets is where we call some other functions. But as we are not calling any function here, we will just leave it blank for now by giving two double quotes
            - instead we will use this call as a transaction
            - give the value like this {value: address(this).balance}
            - unlike send and transfer this call function doesn't have a gas limit, although we can set one
            - and this call() function returns 2 variables
                1. boolean (if the function was successfully called)
                2. bytes (data returned by the function called. Also, since bytes objects are arrays, data returns needs to be in memory)
            - however for our use case as we are not calling any functions we can ignore the 2nd variables returned by the call() function
        */
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!!!!!");
    }
}
