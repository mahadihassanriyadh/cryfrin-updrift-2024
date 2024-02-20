// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/*  
    These are the things we want to do:
    1. Get funds from users
    2. Withdraw funds
    3. Set a minimum funding value in USD
*/

contract FundMe {
    
    /* 
        Just like wallets, contracts can have funds as well. We can send money to it, withdraw money from it, interact with it, etc.
        
        fund() function: users will use this to fund the contract
        1. allow usrs to send $
        2. have a minimum $ amount to send fund

        Q1. But how do we send ETH to this contract? 
            => Whenever we send a tracsaction in a contract (changing the state of the contract) there is always a "value" field. With is set to 0 by default. This value field is the amount of native blockchain currency that gets sent with every transaction.

        - We will need to use the keyword "payable" in our function to access this native blockchain currency
        - we will see remix ui will now make the fund function red color, indicating this function is associated with payments or transfering currencies 
    */
    function fund() public payable {
        /*  
            - we can a global function of solidity msg.value(uint) to access the value property of our contract, we will specify the number of wei sent with the message / transaction here 
            - if we want the user to be required to spend at least one whole ETH with this fund function, we could use something called "require" to do so
            - this will revert the transaction if the conditions are not met
        */
        
        require(msg.value >= 1e18, "didn't send enough ETH"); // 1e18 Wei = 1 ETH, in smart contract this is how they process number, in a very small chunk like Wei, and gas cost are shown in form of Gwei, 1e9 Gwei = 1 ETH


    }

    // we will use this to withdraw funds
    function withdraw() public {

    }
}