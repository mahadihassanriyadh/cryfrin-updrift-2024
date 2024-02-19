// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { SimpleStorage } from "./SimpleStorage.sol";

// Inheritance
contract AddFiveStorage is SimpleStorage {
    function sayHello() public pure returns(string memory) {
        return "Hello";
    }

    /* 
        Override
        wanna modify a function from SimpleStorage / another contract
        to do that we need to ensure two things:
        1. we have used virtual keyword in the base function. This keyword indicates that the function is overridable.
        2. specify override key word in the new function
    */
    function store(uint256 _favNum) public override {
        myFavNum = _favNum + 5;
    }

}