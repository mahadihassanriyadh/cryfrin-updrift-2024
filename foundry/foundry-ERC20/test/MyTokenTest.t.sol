// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployMyToken} from "../script/DeployMyToken.s.sol";
import {MyToken} from "../src/MyToken.sol";
import {console} from "forge-std/console.sol";

contract MyTokenTest is Test {
    MyToken public myToken;
    DeployMyToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address carol = makeAddr("carol");

    uint256 public constant INITIAL_SUPPLY = 1000 ether;
    uint256 public constant STARTING_BALANCE = 50 ether;

    function setUp() public {
        deployer = new DeployMyToken();
        myToken = deployer.run();

        vm.prank(msg.sender);
        myToken.transfer(bob, STARTING_BALANCE);
    }

    function testInitialSupply() public {
        assertEq(myToken.totalSupply(), INITIAL_SUPPLY);
    }

    function testTransfer() public {
        vm.prank(msg.sender);
        myToken.transfer(bob, 100);
        assertEq(myToken.balanceOf(bob), 100 + STARTING_BALANCE);
    }

    function testBobBalance() public {
        assertEq(myToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowancesWorks() public {
        /* 
            ERC20 has a function called transferFrom()
                1. If I want my contract to keep track of how many tokens it has from you, it needs to be the one to actually transfer the tokens from you to itself
                2. In order for it to take the tokens from you, you need to allow it to do so
            The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
        */

        // Test Bob approves Alice to spend some tokens on his behalf
        uint256 initialAllowance = 10 ether;

        vm.prank(bob);
        myToken.approve(alice, initialAllowance);

        uint256 transferAmount = 5 ether;
        vm.prank(alice);
        myToken.transferFrom(bob, carol, transferAmount);

        assertEq(myToken.balanceOf(carol), transferAmount);
        assertEq(myToken.balanceOf(bob), STARTING_BALANCE - transferAmount);

        vm.prank(alice);
        vm.expectRevert();
        myToken.transferFrom(bob, alice, initialAllowance);
    }

    function testFailTransferMoreThanBalance() public {
        vm.prank(bob);
        // vm.expectRevert();
        myToken.transfer(alice, 1 ether);
    }
}
