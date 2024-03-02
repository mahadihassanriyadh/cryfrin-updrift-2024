// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// NatSpec Format: Solidity contracts can use a special form of comments to provide rich documentation for functions, return variables and more. This special form is named the Ethereum Natural Language Specification Format (NatSpec). [https://docs.soliditylang.org/en/latest/natspec-format.html]
/**
 * @title A Simple Raffle Contract
 * @author Md. Mahadi Hassan Riyadh
 * @notice This contract is for creating a simple raffle system.
 * @dev Implements chainlink VRF for random number generation.
 */

contract Raffle {
    error Raffle__NotEnoughEthSent();

    uint256 private immutable i_entranceFee;

    // as one of the players will be paid, so the addresses need to payable
    address payable[] private s_players;

    /*  
        ###############################
        ########## Events ⏳ ##########
        ###############################
    */
    event EnteredRaffle(address indexed player);

    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function enterRaffle() external payable {
        // more gas efficient than require
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {}

    /*  
        ###################################
        ####### Getter Functions ✅ #######
        ###################################
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}

/*  
    ####################################################
    ####### Code Layout & Order (Style Guide) 🎨 #######
    ####################################################

    ⭕️ Contract elements should be laid out in the following order:
        - Pragma statements
        - Import statements
        - Events
        - Errors
        - Interfaces
        - Libraries
        - Contracts

    ⭕️ Inside each contract, library or interface, use the following order:
        - Type declarations
        - State variables
        - Events
        - Errors
        - Modifiers
        - Functions

    ⭕️ Layout of Functions:
        - constructor
        - receive function (if exists)
        - fallback function (if exists)
        - external
        - public
        - internal
        - private
        - view & pure functions 
*/
