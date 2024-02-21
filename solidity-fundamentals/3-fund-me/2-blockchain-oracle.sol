// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract FundMe {
    uint256 public minUsd = 5;

    function fund() public payable {
        /*  
            1. allow users to send $
            2. have a minimum $ sent $5

            ❓But as our msg.value is in Wei and we are setting the min threshold to send money in usd, how do we compare them?
            => Blockchian are determenistic systems. As a result they can't interact with the Real World's data or events. Blockchains can't also do external computation. For example if we have an amazing AI model we wanna integrate with our contract, smart contract by default can't do that. This is known as the blockchain Oracle Problem. Here comes Chainlink Oracle or Blockchain Oracle to the solution, which will let the contracts use Real World data. 

            Blockchain Oracle: Any device that interacts with the off-chain world to provide external data or computation to smart contracts. But if we introduce a centralized oracle then we fell into the same problem again, which we went to solve with Blockchain. That is why Chainlink build a Decentralized Oracle Network.
        */

        require(msg.value >= minUsd, "didn't send enough ETH");
    }

    function withdraw() public {}
}
