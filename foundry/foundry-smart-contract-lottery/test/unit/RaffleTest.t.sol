// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 12 ether;

    /*  
        ###############################
        ########## Events ⏳ ##########
        ###############################
    */
    event EnteredRaffle(address indexed player);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
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
}
