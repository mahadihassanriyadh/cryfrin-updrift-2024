# Provably Random Raffle Contracts

## About
This code is to create a provably random raffle contract. The contract is written in Solidity and is deployed on the Ethereum test net (Sepolia).

## What we can do with this contract?
1. User can enter by paying for a ticket.
    - The ticket fees are going to go to the winner during the raffle.
2. After X period of time, the lottery will automatically pick a winner.
    - And all these will be done programmatically.
3. We will Chainlink VRF & Chainlink Automation to make the lottery provably random and automated.
    - Chainlink VRF -> Randomness
    - Chainlink Automation -> Time based trigger