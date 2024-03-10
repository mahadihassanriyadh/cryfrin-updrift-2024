// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract ManualToken {
    mapping(address => uint256) private s_addressToBalance;

    function name() public pure returns (string memory) {
        return "Manual Token";
    }

    function symbol() public pure returns (string memory) {
        return "MT";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return 100 ether;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return s_addressToBalance[_owner];
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(s_addressToBalance[msg.sender] >= _value);
        uint256 previousBalances = s_addressToBalance[msg.sender] + s_addressToBalance[_to];
        s_addressToBalance[msg.sender] -= _value;
        s_addressToBalance[_to] += _value;
        require(s_addressToBalance[msg.sender] + s_addressToBalance[_to] == previousBalances);
        return true;
    }
}
