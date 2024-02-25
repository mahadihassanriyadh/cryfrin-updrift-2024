// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract SimpleStorage {
    // fabNum variable will get initialized with 0 if no value is given.
    // but this will not be visible to the public, as by defaut a variable's state is set to internal
    // so, uint256 internal favNum; and uint256 favNum; are the same thing
    // to make it visible we need to set the state to public
    /*  
        Functions & Variables in Solidity can have 4 kinds of visibility
        1. public: all can access
        2. private: can be accessed only from this contract
        3. external: Cannot be accessed internally, only externally 
        4. internal (default): only this contract and contracts deriving from it can access
    */
    uint256 public favNum; // 0

    function store(uint256 _favNum) public {
        favNum = _favNum;
    }

    /* 
        We will see there will be three function button now when we deploy our contract
        - orange color
        - blue color: pure, view. These are two special keywords that notates functions that don't actually have to send a txn in order to call them. They do not mutate any state in the blockchain, they just read states from the blockchain. So if we use any of these two keywords we wouldn't be able to perform any state change operation inside that function.
        - view: disallow updating state
        - pure: disallow updating state + reading from state

        Note: However, view and pure function does costs gas only when another function which is using gas for txn call a view or pure function.
    */
    function retrieve() public view returns (uint256) {
        return favNum;
    }

    /* 
        We should also keep in mind, when a txn happens, we should care about the txn cost as this refers to the gas that has been used for the txn. Whereas, gas refers to the amount of gas we sent for the txn to happen.
    */
}
