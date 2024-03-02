// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

// import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

// NatSpec Format: Solidity contracts can use a special form of comments to provide rich documentation for functions, return variables and more. This special form is named the Ethereum Natural Language Specification Format (NatSpec). [https://docs.soliditylang.org/en/latest/natspec-format.html]
/**
 * @title A Simple Raffle Contract
 * @author Md. Mahadi Hassan Riyadh
 * @notice This contract is for creating a simple raffle system.
 * @dev Implements chainlink VRF for random number generation.
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTimePassed();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    /* ############ Type Declarations ############ */
    // In solidity, enums are converted into integers
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_OF_WORDS = 1;

    uint256 private immutable i_entranceFee;
    // minimum time interval between two raffles in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash; // gas lane
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // as one of the players will be paid, so the addresses need to payable
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /*  
        ###############################
        ########## Events ⏳ ##########
        ###############################
    */
    event EnteredRaffle(address indexed player);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // more gas efficient than require
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    /*  
        1. get a random number
        2. use the random number to pick a winner
        3. be automatically called
    */
    function pickWinner() external {
        // check if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert Raffle__NotEnoughTimePassed();
        }

        s_raffleState = RaffleState.CALCULATING;

        /*  
            - Till now all we have been doing was atomic. Everything was happening in one transaction.
            - Now we need to do two transactions when using Chainlink VRF:
                1. Request a random number -> This is a outgoing request transaction to Chainlink VRF
                2. Get the random number (Callback Request) <- This is a incoming recieving transaction coming from Chainlink VRF
        */
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash, // gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_OF_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

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

    ⭕️ Contract Layout:
        - Pragma statements (Version)
        - Import statements
        - Interfaces, Libraries, Contracts
        - Type declarations
        - State variables
        - Events
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
