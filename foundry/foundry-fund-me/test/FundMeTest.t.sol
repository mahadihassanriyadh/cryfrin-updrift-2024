// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

contract FundMeTest is Test {
    uint256 number = 555;

    // this is the first thing that runs before any tests
    function setUp() external {

    }

    function testDemo() public {
        console.log("Hello, World!");
        console.log("Number is: ", number);
        assertEq(number, 555);
    }
}