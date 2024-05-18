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

    uint256 public constant MIN_DELAY = 3600 seconds; // 1 hour; delay after a vote passes and before it is executed

    address[] proposers; // means anyone can propose a vote
    address[] executors; // means anyone can execute a vote

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
}
