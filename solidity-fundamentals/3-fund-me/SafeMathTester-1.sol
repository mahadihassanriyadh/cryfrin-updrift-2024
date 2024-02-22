// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// Safe Math library was very popular before solidity version 0.8
// It was everywhere
// So to test it we will use a version before 0.8

contract SafeMathTester {
    uint8 public num = 255; // the highest num uint8 can store is 255

    function increaseNum() public {
        num += 1;
    }

    // now if we called the function increaseNum() the num var would go to zero (0)
    // kind of like a cycle
    // which may result in unpredictable behaviours
    // that is why we used to use the Safe Math library, in case a var reached it's limit, the library would revert the transaction
    // which is inherent in solodity 0.8.0+
    // so if it's inherent why are we learning about it?
    // Because sometimes we may want to turn of this auto checking feature by solidity to save off some gas like this:
    /*  
        unchecked {num += 1;}
    */
}
