// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// import {Test, console} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinUsdIsFive() public {
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    /* 
        - here FundMeTest is the owner of the FundMe contract as it created it
        - so if we would call msg.sender it would be the sender of the transaction, not the owner of the contract
        - but address(this) gives us the address of our test contract
    */
    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_fundOwner(), address(this));
    }

    /* 
        So our test is reverting. What can we do to work with addresses outside our system?
        1. Unit testing
            - testing a specific part of our code
        2. Integration testing
            - testing how our code works with other parts of our code
        3. Forked
            - testing our code on a simulated real environment
        4. Staging
            - testing our code in a real environment, like testnet or sometimes even in mainnet
            - this is highly important for smart contracts because our real env might be very different from our simulated env
        
        Till now we have done Unit testing, now we will do Integration testing + Forked testing
        To do that we will use our Sepolia RPC URL from Alchemy, and run

        forge test --mt testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL
        OR
        forge test -vvv --fork-url $SEPOLIA_RPC_URL

        Now we will see our test will pass
    */ 
    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
}
