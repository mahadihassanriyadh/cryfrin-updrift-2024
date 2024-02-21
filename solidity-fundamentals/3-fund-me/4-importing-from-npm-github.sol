// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// we can simply import the interface from github
// by seeing "@chainlink/contracts", remix is smart enough to know this is refering to a npm package "@chainlink/contracts" (https://www.npmjs.com/package/@chainlink/contracts)
// so remix is downloading that package for us and using github address to import the interface
// github link (https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol)
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {

    uint256 public minUsd = 5;

    function fund() public payable {
        require(msg.value >= minUsd, "didn't send enough ETH"); 
    }

    function getPrice() public {

    }

    function getVersion() public view returns(uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }

    function getConversionRate() public {

    }

    function withdraw() public {

    }
}