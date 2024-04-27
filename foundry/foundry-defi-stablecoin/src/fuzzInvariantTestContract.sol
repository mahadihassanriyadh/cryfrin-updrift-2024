// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract FuzzInvariantTestContract {
    uint256 public shouldAlwaysBeZero = 0;
    uint256 private hiddenValue = 0;

    function doStuff(uint256 data) public {
        // 🐞 BUG 1
        // if (data == 2) {
        //     shouldAlwaysBeZero = 1;
        // }

        // 🐞 BUG 2
        // if (hiddenValue == 7) {
        //     shouldAlwaysBeZero = 1;
        // }
        
        hiddenValue = data;
    }
}
