// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_value;

    event ValueChanged(uint256 value);

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    function store(uint256 _newNumber) public onlyOwner {
        s_value = _newNumber;
        emit ValueChanged(_newNumber);
    }

    function getValue() public view returns (uint256) {
        return s_value;
    }
}
