// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {FuzzInvariantTestContract} from "../../../src/fuzzInvariantTestContract.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
/* 

contract TestContractFuzzing is StdInvariant, Test {
    FuzzInvariantTestContract fuzzInvariantTestContract;

    function setUp() public {
        fuzzInvariantTestContract = new FuzzInvariantTestContract();
        targetContract(address(fuzzInvariantTestContract));
    }

    function testIAlwaysGetZero() public {
        uint256 data = 0;
        fuzzInvariantTestContract.doStuff(data);
        assert(fuzzInvariantTestContract.shouldAlwaysBeZero() == 0);
    }

    function testIAlwaysGetZeroFuzz(uint256 data) public {
        // uint256 data = 0;
        fuzzInvariantTestContract.doStuff(data);
        assert(fuzzInvariantTestContract.shouldAlwaysBeZero() == 0);
    }

    // by making our TestContractTest A StdInvariant, and by calling the targetContract function in the setUp function, we can now do stateful fuzz testing
    // foundry is smart enough to know, it's gonna grab any or all the functions of the contract and call them in random order with random inputs while keeping track of the state
    // for example if we input 7, the hiddenVallue would be 7
    // and in the next doStuff call, the hiddenValue would still be 7, so whatever we input now shouldAlwaysBeZero would become 1
    function invariant_testIAlwaysGetZero() public view {
        assert(fuzzInvariantTestContract.shouldAlwaysBeZero() == 0);
    }
}

*/