// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract ManualToken {
    function name() public pure returns (string memory) {
        return "Manual Token";
    }

    function symbol() public pure returns (string memory) {
        return "MT";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256)
    {
        return 100 ether;
    }
}
