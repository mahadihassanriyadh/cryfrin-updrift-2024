// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Safe Math library was very popular before solidity version 0.8
// It was everywhere
// So to test it we will use a version before 0.8

contract SafeMathTester {
    uint8 public num = 255; // the highest num uint8 can store is 255

    function increaseNum() public {
        unchecked {num += 1;}
    }
}
