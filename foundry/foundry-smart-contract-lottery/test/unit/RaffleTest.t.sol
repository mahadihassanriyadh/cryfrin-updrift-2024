// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    uint256 deployerKey;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 12 ether;

    /*  
        ###############################
        ########## Events ⏳ ##########
        ###############################
    */
    event EnteredRaffle(address indexed player);

    /*  
        ##################################
        ########## Modifiers 🙌 ##########
        ##################################
    */
    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // now we need to kick of a performUpkeep to get the raffle into the calculating state
        // in order to do this we need our checkUpkeep to return true
        // first thing we need to do is pass enough time
        // foundry gives us some cheats to do this fairly easily when we are working on a local chain, we can set the block.timestamp ourselves
        vm.warp(block.timestamp + interval + 1);
        // we don't have to do vm.roll() but we are just doing an extra block in our test
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit,
            link,
            // deployerKey
        ) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /*  
        #####################################
        ########## Enter Raffle 🧬 ##########
        #####################################
    */
    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);

        // Assert
        raffle.enterRaffle{value: 0.001 ether}();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        raffle.enterRaffle{value: entranceFee}();

        // Assert
        assert(raffle.getPlayers().length == 1);
        assert(raffle.getPlayers()[0] == PLAYER);
    }

    function emitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        /*  
            - we are saying it has 1 indexed parameter (topic) out of three. 
            - Then we are asking are there any data or unindexed parameters? As we do not have any data or unindexed parameters, we pass false as the fourth argument as well. 
            - Finally we are passing the address of the emitter as the fifth argument, for now which is the raffle contract.
            ----------------------------------------------------------------
            - Now have to redefine our events here in the test file as well. As events are not types or structs, they are not automatically imported from the contract. We have to define them again in the test file. Like so:
                event EnteredRaffle(address indexed player);
            ----------------------------------------------------------------
            So what we are doing here is:
                1. We are saying we expect an event to be emitted.
                2. The event will be like this: EnteredRaffle(PLAYER), means we have manually emitted the event we are expecting
                3. Then finally we cann the function enterRaffle which should emit this event. Otherwise the test will fail.

        */
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);

        // Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating()
        public
        raffleEnteredAndTimePassed
    {
        raffle.performUpkeep("");

        // now we shouldn't be able to enter the raffle
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*  
        #####################################
        ########## checkUpkeep 🔼 ##########
        #####################################
    */
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen()
        public
        raffleEnteredAndTimePassed
    {
        // Arrange
        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfItHasNoPlayers() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfAllParametersAreGood()
        public
        raffleEnteredAndTimePassed
    {
        // Arrange

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }

    /*  
        ######################################
        ########## performUpkeep 🎤 ##########
        ######################################
    */
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        public
        raffleEnteredAndTimePassed
    {
        // Arrange

        // Act / Assert
        // the test shall pass if the performUpkeep function does not revert
        // and as we have already tested the checkUpkeep function, we know that it will return true, so the performUpkeep function should not revert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numOfPlayers = 0;

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numOfPlayers,
                Raffle.RaffleState.OPEN
            )
        );
        raffle.performUpkeep("");
    }

    // testing output of an event
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEnteredAndTimePassed
    {
        // Arrange

        /*  
            // Act
            - We are going to use another cheat code here to test the output of an event
            - There is a cheatcode in foundry called 'recordLogs', which tells the VM to start recording all the emitted events.
            - To access them we can use 'getRecordedLogs'
        */
        vm.recordLogs();
        raffle.performUpkeep(""); // this is going to emmit the requestId
        Vm.Log[] memory logs = vm.getRecordedLogs(); // Vm.Log is an special type provided by foundry and this line will get all the logs which was recently emitted
        /*  
            But how do we know which log is the one we are interested in? Maybe the function is emitting multiple logs.
            - One of the ways is to use the Foundry debugger by using
                forge test --debug "$FUNCTION_NAME"

                eg. forge test --debug "testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()"
            - For now, we are going to cheat a little bit as we know our emitted event will be in the 2nd position, first event would be emitted by requestRandomWords function in the mocks
        */
        bytes32 requestId = logs[1].topics[1]; // we are getting the requestId from the logs
        // even though requestId is the first topic in the event, topics[0] indicates to the whole event rather than the first topic
        // but the logs[1] refers to the second log emitted by the performUpkeep function. This is the second event becaue the first event was emitted by the requestRandomWords function in the mocks
        // also all the logs are returned as bytes32

        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(rState == Raffle.RaffleState.CALCULATING);
        assert(uint256(rState) == 1);
    }

    /*  
        ###########################################
        ########## fulfillRandomWords 🎁 ##########
        ###########################################
    */
    function testFulFillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 _randomRequestId
    ) public raffleEnteredAndTimePassed {
        // Arrange
        vm.expectRevert("nonexistent request");

        // Act
        // This should fail as we haven't called performUpkeep yet
        // And are expecting a "nonexistent request" error, because this is defined in the mock, if the requestId is not found, the mock should revert with this error
        // However, we should test this for different randomRequestIds as well instead of just one or two. For example if we just passed 0 or 1 our test would still go through, but we did not test if the next line will revert if we pass 10 or 55 etc.
        // That is where the "Fuzz Test" comes in, where we test the same function with different inputs
        // we can take a parameter call randomRequestId and then we can just pass it to the VRFCoordinatorV2Mock and foundry will randomly select different number and test the function with different inputs
        // ⭐️ we are the one pretending to be the Chainlink VRF here, the reason is we do not have a read Chainlin VRF in the testing environment, thus we are using the VRFCoordinatorV2Mock to pretend to be the Chainlink VRF
        // so this test won't work if we work on some real test chain or real chain overall
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            _randomRequestId,
            address(raffle)
        );
    }

    function testFulFillRandomWordsPicksAWinnerResetAndSendsMoney()
        public
        raffleEnteredAndTimePassed
    {
        // Arrange
        uint256 additionalEntrance = 5;
        uint256 startingIdx = 1;
        for (uint256 i = startingIdx; i <= additionalEntrance; i++) {
            address player = address(uint160(i));
            // hoax is another cheatcode by foundry to setup prank user and send ether to the contract
            // so, prank + deal = hoax
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 previousTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = address(raffle).balance;

        // Act
        // pretend to be chainlink VRF to get the random number & pick the winner
        vm.recordLogs();
        raffle.performUpkeep(""); // this is going to emmit the requestId
        Vm.Log[] memory logs = vm.getRecordedLogs(); // Vm.Log is an special type provided by foundry and this line will get all the logs which was recently emitted
        bytes32 requestId = logs[1].topics[1];
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getPlayers().length == 0);
        assert(raffle.getLastTimeStamp() > previousTimeStamp);
        assert(address(raffle).balance == 0);
        assert(
            raffle.getRecentWinner().balance ==
                STARTING_USER_BALANCE + prize - entranceFee
        );

        assertEq(
            logs[1].topics[0],
            keccak256("RequestedRaffleWinner(uint256)")
        );
        // previous vm.getRecordedLogs() consumed all the emitted logs till then, so now we will get newly emitted logs after our last recordLogs() call
        logs = vm.getRecordedLogs();
        console.log(
            "Log Topic Address",
            address(uint160(uint256(logs[0].topics[1])))
        );
        console.log("Recent Winner Address", raffle.getRecentWinner());
        assertEq(logs[0].topics[0], keccak256("PickedWinner(address)"));
        assertEq(
            logs[0].topics[1],
            bytes32(uint256(uint160(raffle.getRecentWinner())))
        );
        // address emittedWinner = address(uint160(uint256(updatedLogs[2].topics[1])));
        // assert(emittedWinner == raffle.getRecentWinner());
    }
}
