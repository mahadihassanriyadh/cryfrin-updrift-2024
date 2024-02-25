// SPDX-License-Identifier: MIT

// telling our compiler which version of solidity we are using in this contract
// ^0.8.24 represents, 0.8.24 version or greater versions will work with this contract
// >=0.8.24 <0.9.0, this would tell the compiler any version between 0.8.24 and 0.9.0 is a valid version
pragma solidity ^0.8.24;

contract SimpleStorage {
    // Basic Types: uint, int, boolean, address, bytes (lower level types)
    // uint: unsigned integer, meaning no decimal, no fraction  [0, infinity)
    // int: signed integer (-infinity, infinity)
    
    bool hasFavNum = true;

    // we can also define how many bits we wanna use
    // by default the bits is 256, so uint and uint256 are the same thing.
    // but it's better to write the num of bits, explicitly.
    uint256 favNum1 = 99; 
    int256 favNum2 = -55;
    string favNumInText = "99";
    address myFirstAdd = 0xaD1C737896cd841766BED18dd052d8244331e1DB;

    // NOTE: although uint256 and uint are same, bytes32 and bytes are not.
    // Strings are actually arrays in Solidity and are very similar to byte arrays
    bytes32 favBytes32 = "hello world!";
}