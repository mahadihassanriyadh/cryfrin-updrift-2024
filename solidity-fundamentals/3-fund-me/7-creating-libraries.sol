// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter } from "../library/PriceConverter.sol";

contract FundMe {
    /*  
        Creating librarries in solidity
        --------------------------------
        https://solidity-by-example.org/library/
        - Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.
        - A library is embedded into the contract if all library functions are internal.
        - Otherwise the library must be deployed and then linked before the contract is deployed.
        --------------------------------
        - Using libraries can add functionalities to different values
        - Means we can have our getConversionRate() function be a function of any value of type uint256
        - measns we could do something like this, msg.value.getConversionRate()
        - so we can create our own custom function with any type
        - We could work with getConversionRate as if message.value was a class or object or contract that we created.
        - to attach our PriceConverter library to all uint256 we will do something like this
            using PriceConverter for uint256;
        - now we call msg.value.getConversionRate()
        - when we are using a library, the function will get the type value we have attached library with as the first parameter. In our case uint56. So our function will automatically get msg.value as the first parameter. 
        - if we wanna send a second parameter we can do so by msg.value.getConversionRate(secondParam)
    */

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
        addressToAmountFunded[msg.sender] =
            addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function withdraw() public {}
}
