// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinUsdIsFive() public {
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    /* 
        - here FundMeTest is the owner of the FundMe contract as it created it
        - so if we would call msg.sender it would be the sender of the transaction, not the owner of the contract
        - but address(this) gives us the address of our test contract
    */
    function testOwnerIsMsgSender() public {
        console.log("fundMe.i_fundOwner()", fundMe.i_fundOwner());
        console.log("address(this)", address(this));
        console.log("msg.sender", msg.sender);
        assertEq(fundMe.i_fundOwner(), address(this));
    }
}