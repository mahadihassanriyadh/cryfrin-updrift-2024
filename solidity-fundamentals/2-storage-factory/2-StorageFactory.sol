// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { SimpleStorage } from "./SimpleStorage.sol";

contract StorageFactory {
  // SimpleStorage[] public arrOfSimpleStorage;
  address[] public listOfSimpleStorageAddresses;

  function createNewStorageContract() public {
    SimpleStorage newSimpleStorage = new SimpleStorage();
    address newSimpleStorageAddress = address(newSimpleStorage);
    listOfSimpleStorageAddresses.push(newSimpleStorageAddress);
  }

  function sfStore(uint256 _contractIdx, uint256 _favNum) public {
    /* 
      Explicit Typecasting
      We are converting address type to our SimpleStore Contract type
      The below line is simply wrapping the address with SimpleStore type
      SimpleStorage(address)
    */
    SimpleStorage(listOfSimpleStorageAddresses[_contractIdx]).store(_favNum);
  }

  function sfRetrive(uint256 _contractIdx) public view returns(uint256) {
    // return arrOfSimpleStorage[_contractIdx].retrieve();
    return SimpleStorage(listOfSimpleStorageAddresses[_contractIdx]).retrieve();
  }
}