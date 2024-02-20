// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract FundMe {

    uint256 public minUsd = 5;

    function fund() public payable {
        require(msg.value >= minUsd, "didn't send enough ETH"); 
    }

    function getPrice() public {
        // to get the price from oracle's contract, we need to have two things again
        // 1. Addresss 0x694AA1769357215DE4FAC081bf1f309aDC325306 ETH/USD
        // 2. ABI
        // Before we imported the whole contract here so we automatically kind of got the ABI. However now we can't do that. But what is this ABI actually is? We can think of it as the structure of our Contract. Like which function it contains, which function returns what and so on. So this is basically a Contract Type. We can have any ContractType and pass in any contract's address of that type and we will be able to use any functions or data from that contract.
        
    }
    
    function getVersion() public view returns(uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }

    function getConversionRate() public {

    }

    function withdraw() public {

    }
}