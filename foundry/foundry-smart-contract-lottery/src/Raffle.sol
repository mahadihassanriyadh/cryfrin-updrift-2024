// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

// import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

// NatSpec Format: Solidity contracts can use a special form of comments to provide rich documentation for functions, return variables and more. This special form is named the Ethereum Natural Language Specification Format (NatSpec). [https://docs.soliditylang.org/en/latest/natspec-format.html]
/**
 * @title A Simple Raffle Contract
 * @author Md. Mahadi Hassan Riyadh
 * @notice This contract is for creating a simple raffle system.
 * @dev Implements chainlink VRF for random number generation.
 */

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTimePassed();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        RaffleState raffleState
    );

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
    bytes32 private immutable i_keyHash; // gas lane
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

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
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

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

    // When is the winner supposed to be picked?
    /**
     * @dev This is the function that the Chainlink Automation nodes call to see if it's time to perform an upkeep.
     * The following should be true for this to return true:
     * 1. The time interval has passed between the last raffle and now
     * 2. The raffle is in the OPEN state
     * 3. The contract has ETH (aka, players have entered the raffle)
     * 4. (Implicit) The subscription is funded with LINK
     * @dev This checkUpkeep will be called by the Chainlink nodes to see if it's time to perform an upkeep. As the function is a view function, it doesn't change the state of the contract, so no transaction is needed to call this function.
     */
    // if our function requires a input parameter and for the chain link nodes to recognize this function, we need an input parameter, but we are not going to use that parameter, then we can just ignore it by wrapping it in a comment
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        // check if enough time has passed
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);

        /*  
            - it wouldn't be a problem if we didn't return anything, as we have named the return variables in the function signature, it would automatically return the value of upkeepNeeded
            - but it's a good practice to be explicit about what we are returning
            So we will:
                1. return the value of upkeepNeeded
                2. return an empty bytes array as performData (as we don't need to return anything here)
        */
        return (upkeepNeeded, "0x0");
    }

    /*  
        1. get a random number
        2. use the random number to pick a winner
        3. be automatically called
    */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                RaffleState(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        /*  
            - Till now all we have been doing was atomic. Everything was happening in one transaction.
            - Now we need to do two transactions when using Chainlink VRF:
                1. Request a random number -> This is a outgoing request transaction to Chainlink VRF
                2. Get the random number (Callback Request) <- This is a incoming recieving transaction coming from Chainlink VRF
        */
        // requestRandomWords() function is used to send the request for random values to Chainlink VRF.
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash, // gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_OF_WORDS
        );

        // Is this redundant that we are emitting the requestId here?
        // the answer is yes, because if we go to the VRFCoordinatorV2Mock contract, we will see an event 'RandomWordsRequested' is already emitted in the 'requestRandomWords' function. So wheneve we call the 'requestRandomWords' function, the 'RandomWordsRequested' event will be emitted. Which contains the requestId. So we don't need to emit the requestId here.
        // however we are doing it here just to perform a test, the reason we're going to do that is because in our test, we're going to asnwer this question, What if I need to test using the output of an event? As we already know events are not accessible from a contract. But in solidity we can test the events
        emit RequestedRaffleWinner(requestId);
    }

    // Chainlink VRF fulfills the request and returns the random values to your contract in a callback to the fulfillRandomWords() function.
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        // reset the raffle
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        // emit an event
        emit PickedWinner(winner);
    }

    /*  
        ###################################
        ####### Getter Functions ✅ #######
        ###################################
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayers() external view returns (address payable[] memory) {
        return s_players;
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
