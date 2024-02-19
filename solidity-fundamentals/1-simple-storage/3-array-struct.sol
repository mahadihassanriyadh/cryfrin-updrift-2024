// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract SimpleStorage {
    uint256 myFavNum; // 0

    // array
    uint256[] listOfFavNums; // []

    // in solidity we can create custom types using struct
    struct Person {
        uint256 favNum;
        string name;
    }

    // Person public myFriend = Person(33, "Shafin");
    /* 
        Person public shafin = Person({favNum: 33, name: "Shafin"});
        Person public maria = Person({favNum: 177, name: "Maria"});
        Person public faruk = Person({favNum: 235, name: "Faruk"}); 
    */
    
    // dynamic array: size of the array can grow and shrink
    Person[] public dynamicListOfPeople; // []

    // static array: size of the array is fixed
    // Person[3] public staticListOfPeople;

    function store(uint256 _favNum) public {
        myFavNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return myFavNum;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        dynamicListOfPeople.push( Person({name: _name, favNum: _favNum}) );
    }
}