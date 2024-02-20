// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*  
    These are the things we want to do:
    1. Get funds from users
    2. Withdraw funds
    3. Set a minimum funding value in USD
*/

contract FundMe {
    
    // users will use this to fund the contract
    function fund() public {
        // allow usrs to send $
        // have a minimum $ amount to send fund
        /* 
            Q1. But how do we send ETH to this contract? 
                => Whenever we send a tracsaction in a contract (changing the state of the contract) there is always a value field. With is set to 0 by default.
        */


    }

    // we will use this to withdraw funds
    function withdraw() public {

    }
}