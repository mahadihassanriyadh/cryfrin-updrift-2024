// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// import {Test, console} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("User");
    uint256 constant SEND_VALUE = 0.1 ether; // 1e17 wei
    uint256 constant STARTING_BALANCE = 8e18; // 8 ether

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        // give some funds to the fake user
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinUsdIsFive() public {
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_fundOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert
        fundMe.fund{value: 1e8}(); // sending 0 wei or 1e8 wei which is <= 5$, should revert
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next Tx will be from the fake user
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    // the reason vm.prank we used in the previous test won't cause any problem here is, how the test works here. 
    // so every time what happens is,
    // 1. the setUp() function is called
    // 2. a test function is called
    // 3. repeat 1 and 2 for all the test functions
    function testAddFundersToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
}
