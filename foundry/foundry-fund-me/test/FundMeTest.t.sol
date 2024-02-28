// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// import {Test, console} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("User");
    uint256 constant SEND_VALUE = 5 ether; // 1e17 wei
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
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert
        fundMe.fund{value: 1e8}(); // sending 0 wei or 1e8 wei which is <= 5$, should revert
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFundersToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // the next line should revert, it will skip the vm.prank(USER) line, it only works for tx
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange: First arrange or setup the test
        // balance of the owner before the withdraw
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // balance of the contract before the withdraw
        uint256 startingContractBalance = address(fundMe).balance;

        // Act: Then do the actions we want to test
        // call the withdraw function as the owner
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert: And finally assert the test
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingContractBalance
        );
        assertEq(endingContractBalance, 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numOfFunders = 10;
        uint160 startingFunderIdx = 1;
        // The reason we are starting from 1 is, because sometimes the address(0) will reverse and won't let us do stuff with it
        for (uint160 i = startingFunderIdx; i < numOfFunders; i++) {
            /* 
                We could do something like this:
                1. vm.prank(USER); // create a new user
                2. vm.deal(USER, 1e18); // give the user some funds

                However, foundry gives us another cheatcode `hoax` which is a combination of `prank` and `deal`
                So we can do this instead:
                    hoax(address, value)
            */
            // previous we have seen we can create an address with address(0)
            // we can do this with other numbers as well, just the number has to be in uint160 as uint160 has the same byte size as address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // Act
        /* 
            vm.prank(fundMe.getOwner());
            fundMe.withdraw(); 
        */
        // We can do the above two lines, but we can also do this:
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();       

        // Assert
        assertEq(
            fundMe.getOwner().balance,
            startingOwnerBalance + startingContractBalance
        );
        assertEq(address(fundMe).balance, 0);
    }
}
