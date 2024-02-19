// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract SimpleStorage {
    uint256 myFavNum; // 0

    uint256[] listOfFavNums; // []

    struct Person {
        uint256 favNum;
        string name;
    }

    Person[] public dynamicListOfPeople; // []

    // mapping type (this is similar to python's dictionary / js's object)
    // type visibility varName
    // mapping(keyType => valueType)
    mapping(string => uint256) public nameToFavNumber;

    function store(uint256 _favNum) public {
        myFavNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return myFavNum;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        dynamicListOfPeople.push( Person({name: _name, favNum: _favNum}) );
        nameToFavNumber[_name] = _favNum;
    }
}