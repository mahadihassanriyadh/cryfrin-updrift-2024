// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract SimpleStorage {
    uint256 public myFavNum;

    struct Person {
        string name;
        uint8 age;
        uint256 favNum;
    }

    mapping(string => Person) nameToPersonDetails;

    function storeMyFavNum(uint256 _myFavNum) public {
        myFavNum = _myFavNum;
    }

    function retrieveMyFavNum() public view returns (uint256) {
        return myFavNum;
    }

    function storePersonDetails(
        string memory _name,
        uint8 _age,
        uint256 _favNum
    ) public {
        nameToPersonDetails[_name] = Person(_name, _age, _favNum);
    }
}
