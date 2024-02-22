// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter} from "./library/PriceConverter.sol";

/* 
    - wow! our FundMe contract works fine and awesome
    - now we will try to improve our code a little bit
    - we can see we are using some variables which are only set once
    - minUsd was set once and was never changed
    - fundOwner was set once and was never changed
    - let's try to make these a little more gas efficient 
    - currently our contract costs around 8,39,802 gas
    
    ----------------------------------------------
    ------------------ constant ------------------
    ----------------------------------------------
    - we can use constant keyword infront of a var which we will never change
    - it will cost in less gas, because wehen we use the constant keyword with a variable it doesn't take much space and easier to read too
    - let's make the minUsd a constant var and check the gas cost again
    - wow, 8,20,517
    - awesome, right?
    - now change the var name to all capital letters (Convension)
    - also as the var became constant it is cheaper to read from
    - before constant read execution cost 2,402 gas
    - after constant read execution cost 303 gas

    ----------------------------------------------
    ------------------ immutable ------------------
    ----------------------------------------------
    - now there can be some var which we won't set immidiately with declaration
    - such as our fundOwner var is set from constructor()
    - we can mark these var as immutable
    - and add a i_ infront of the var name to make it more obhious that this var is immutable (Convension)
    - before doing so contract gas cost 8,20,517
    - after 7,97,358
    - wow!!!!
    - let's see the read difference 
    - before 2552
    - after 417
    - damn!!!!
*/

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 5e18;

    address chainlinkAggregatorV3InterfaceAddressEthUsd =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_fundOwner;

    constructor() {
        i_fundOwner = msg.sender;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate() >= MIN_USD,
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

    modifier onlyOwner() {
        require(
            msg.sender == i_fundOwner,
            "You are not authorized to withdraw the fund!"
        );
        _;
    }
}
