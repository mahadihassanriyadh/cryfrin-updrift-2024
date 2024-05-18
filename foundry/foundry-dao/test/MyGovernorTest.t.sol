// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {GovToken} from "../src/GovToken.sol";

contract MyGovernorTest is Test {
    MyGovernor governor;
    Box box;
    TimeLock timeLock;
    GovToken govToken;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    uint256 public constant MIN_DELAY = 3600; // 1 hour; delay after a vote passes and before it is executed
    uint256 public constant VOTING_DELAY = 7200; // 1 day; delay before a vote starts (How many blocks till the vote starts after proposal is created)
    uint256 public constant VOTING_PERIOD = 50400; // 1 week; considering 1 block per 12 seconds (How many blocks till the vote is closed)

    address[] proposers; // means anyone can propose a vote
    address[] executors; // means anyone can execute a vote

    address[] targets;
    uint256[] values;
    bytes[] calldatas;

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);
        /**
         * @notice First we need some governance token to participate in the governance of the protocol
         * delegeting voting power to myself, I could also delegate the voting power to another address as well
         * whenever we delegate voting power, a checkpoint is created
         * And the GovToken keeps a history (checkpoints) of each account's vote power.
         * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
         */
        vm.startPrank(USER);
        govToken.delegate(USER);

        /**
         * @notice Now that we have some governance token, we can create a timelock contract
         */
        timeLock = new TimeLock(MIN_DELAY, proposers, executors);

        governor = new MyGovernor(govToken, timeLock);

        /**
         * @notice Now we have to grant some roles to the governor contract
         * The timeLock actually starts with some default roles
         * And we need to grant the governor some roles
         * ⭐️⭐️⭐️ Also we need to remove ourselves as the admin of the timeLock
         */
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(governor)); // only the governor can propose stuff to the timeLock
        timeLock.grantRole(executorRole, address(0)); // anyone can execute a proposal
        timeLock.renounceRole(adminRole, USER); // remove ourselves as the admin of the timeLock

        box = new Box(USER);
        box.transferOwnership(address(timeLock));
        vm.stopPrank();
    }

    function testCantUpdateBoxWithoutVote() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 566;
        targets.push(address(box));
        values.push(0);
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
        calldatas.push(encodedFunctionCall);
        string memory description = "Update Box Value with the value 566";

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // View the state of the proposal
        /*  
            // We get this:
            enum ProposalState {
                Pending, // 0
                Active, // 1
                Canceled, // 2
                Defeated, // 3
                Succeeded, // 4
                Queued, // 5
                Expired, // 6
                Executed // 7
            }
        */
        console.log("Proposal State: ", uint256(governor.state(proposalId)));
        assertEq(uint256(governor.state(proposalId)), 0);

        // speed up the time to start the VOTING PERIOD
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State: ", uint256(governor.state(proposalId)));
        assertEq(uint256(governor.state(proposalId)), 1);

        // 2. Vote on the proposal
        /*  
            enum VoteType {
                Against, // 0
                For, // 1
                Abstain // 2
            }
        */
        string memory reason = "I want to update the box value";
        uint8 voteWay = 1; // For (Voting yes)

        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        // 3. Queue the proposal or transaction
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);
        
        // 4. Execute the proposal
        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(box.getValue(), valueToStore);
        console.log("Box Value: ", box.getValue());
    }
}
