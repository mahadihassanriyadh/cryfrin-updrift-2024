// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// importing all the contracts at once (NOT Recommended)
// import "./SimpleStorage.sol";

// Advance import / Named import (Recommended)
import { SimpleStorage } from "./SimpleStorage.sol";

contract StorageFactory {

    // type visibility varName
    // SimpleStorage public simpleStorage;

    // we need to have an array or dict type if we wanna keep track of all the newly created contract
    SimpleStorage[] public listOfSimpleStorageContracts;

    function createSimpleStorageContract() public {
        // this "new" keyword is how solidity knows to deploy a contract
        // simpleStorage = new SimpleStorage();

        // adding our new contract to an array
        listOfSimpleStorageContracts.push(new SimpleStorage());
    }   

    //  sf - storage factory
    // accessing the store() function from SimpleStorage contract
    function sfStore(uint256 _contractIdx, uint256 _newSimpleStorageNum) public {
        // to intereact with another contract, we always need two things
        // 1. Address
        // 2. ABI - Application Binary Interface (technically a lie, we just need the function selector)
        // whenever we import SimpleStorage we automatically get the ABI for it

        // getting a created SingleStorage Contract
        SimpleStorage mySimpleStorage = listOfSimpleStorageContracts[_contractIdx];
        mySimpleStorage.store(_newSimpleStorageNum);
    }

    // accessing the retrieve() function from SimpleStorage contract
    function sfRetrieve(uint256 _contractIdx) public view returns(uint256) {
        SimpleStorage mySimpleStorage = listOfSimpleStorageContracts[_contractIdx];
        return mySimpleStorage.retrieve();
    }
}