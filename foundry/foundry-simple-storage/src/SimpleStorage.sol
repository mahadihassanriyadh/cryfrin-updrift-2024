// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract SimpleStorage {
    uint256 public data;

    function set(uint256 _data) public {
        data = _data;
    }
}

// SPDX-License-Identifier: MIT