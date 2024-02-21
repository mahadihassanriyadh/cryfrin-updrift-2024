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

        - We will need to use the keyword "payable" in our function in order to receive or access native currency through our function
        - we will see remix ui will now make the fund function red color, indicating this function is associated with payments or transfering currencies 
    */
    uint256 public myValue = 0;

    function fund() public payable {
        /*  
            - we can a global function of solidity msg.value(uint) to access the value property of our contract, we will specify the number of wei sent with the message / transaction here 
            - if we want the user to be required to spend at least one whole ETH with this fund function, we could use something called "require" to do so
            - this will revert the transaction if the conditions are not met
        */
        myValue += 1;
        require(msg.value >= 1e18, "didn't send enough ETH"); 
        // 1e18 Wei = 1 ETH, in smart contract this is how they process number, in a very small chunk like Wei, and gas cost are shown in form of Gwei, 1e9 Gwei = 1 ETH

        /* 
            What is a revert? 
            => Undo any actions that have been done, and send the remaining gas back. In our above exaple if the transaction can't go through, the as the value of it is not >= 1e18 our transaction will be reverted, as well as any states that was changed. In our example, if a transaction is reverted any change in myValue variable in the above line will be reverted as well.

            But, did we spent gas even if the transaction didn't go through?
            => Unfortunately, the answer is yes. Even if we send a failed trasaction we will spend gas. Because the computers or nodes executed myValue += 1; line first then executed the line that blocked the transaction. So we should always try to put codes, that might require heavy gas after the require line. So that we only compute things when we are sure the transaction will go through, as a result less waste of gas.
        */

        /*  
            Every single transactions that we send will have these properties:
            1. Nonce: tx count for the account
            2. Gas Price: price per unit of gas (in Wei)
            3. Gas Limit: max gas that this tx can use
            4. To: address that the tx is sent to
            5. Value: amount of Wei to send
            6. Data: what to send to the To address
            7. v, r, s: components of tx signature
        */

    }

    // we will use this to withdraw funds
    function withdraw() public {

    }
}