// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// import {Test, console} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
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
        fundMe.fund{value: 2e18}();
        assertEq(fundMe.funders(0), address(this));
        assertEq(fundMe.addressToAmountFunded(address(this)), 1e18);
    }
}
