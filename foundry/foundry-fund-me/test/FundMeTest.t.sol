// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// import {Test, console} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("User");
    uint256 constant SEND_VALUE = 0.1 ether; // 1e17 wei
    uint256 constant STARTING_BALANCE = 8e18; // 8 ether

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        // give some funds to the fake user
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinUsdIsFive() public {
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_fundOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert
        fundMe.fund{value: 1e8}(); // sending 0 wei or 1e8 wei which is <= 5$, should revert
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next Tx will be from the fake user
        fundMe.fund{value: SEND_VALUE}();
        /* 
            Using sender.msg vs address(this) is getting a little confusing
            Foundry gives us the ability to do this in a more controlled way, by making fake users
            1. Create a fakeuser using
                address USER = makeAddr("User"); 
                - this will create a fake user and return the address
                - this makeAddr is part of forge-std library
            2. Let the test know the next Tx will be from the fake user
                -  this is a cheatcode of foundry and only available in foundry test environment
                vm.prank(USER);
            3. Now, the next Tx will be from the fake user
            4. But the fake user doesn't have any funds, so we need to give it some funds
                - We can use the deal to set some balance for the fake user
                - this is also a cheatcode of foundry and only available in foundry test environment
                vm.deal(USER, STARTING_BALANCE);
        */
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        console.log("amountFunded", amountFunded);
        assertEq(amountFunded, SEND_VALUE);
    }
}
