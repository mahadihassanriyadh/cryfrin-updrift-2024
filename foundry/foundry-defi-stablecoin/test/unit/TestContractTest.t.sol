// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {FuzzInvariantTestContract} from "../../src/fuzzInvariantTestContract.sol";

contract TestContractTest is Test {
    FuzzInvariantTestContract fuzzInvariantTestContract;

    function setUp() public {
        vm.startBroadcast();
        fuzzInvariantTestContract = new FuzzInvariantTestContract();
        vm.stopBroadcast();
    }

    function testIAlwaysGetZero() public {
        uint256 data = 0;
        fuzzInvariantTestContract.doStuff(data);
        assert(fuzzInvariantTestContract.shouldAlwaysBeZero() == 0);
    }

    function testIAlwaysGetZeroFuzz() public {
        uint256 data = 0;
        fuzzInvariantTestContract.doStuff(data);
        assert(fuzzInvariantTestContract.shouldAlwaysBeZero() == 0);
    }

    function testIAlwaysGetZeroFuzz2() public {
        uint256 data = 0;
        fuzzInvariantTestContract.doStuff(data);
        assert(fuzzInvariantTestContract.shouldAlwaysBeZero() == 0);
    }
}
