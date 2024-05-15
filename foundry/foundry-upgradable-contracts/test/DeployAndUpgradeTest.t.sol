// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";

contract DeployAndUpgradeTest is Test {
    DeployBox public deployer;
    UpgradeBox public upgrader;

    address public proxy;

    function setUp() public {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();

        proxy = deployer.run(); // right now points to BoxV1
    }

    function testBox1Works() public view {
        BoxV1 boxV1 = BoxV1(proxy);
        assertEq(boxV1.version(), 1, "BoxV1 should have version 1");
        assertEq(boxV1.getValue(), 999, "BoxV1 should have default number 999");
    }

    function testDeploymentIsV1() public {
        address proxyAddress = deployer.deployBox();
        uint256 expectedValue = 999;
        BoxV1 boxV1 = BoxV1(proxyAddress);
        assertEq(boxV1.version(), 1, "BoxV1 should have version 1");
        assertEq(boxV1.getValue(), 999, "BoxV1 should have default number 999");
        vm.expectRevert();
        BoxV2(proxyAddress).setValue(expectedValue);
    }

    function testUpgradeWorks() public {
        BoxV2 boxV2 = new BoxV2();

        vm.prank(BoxV1(proxy).owner());
        BoxV1(proxy).transferOwnership(msg.sender);

        upgrader.upgradeBox(proxy, address(boxV2));

        uint256 expectedValue = 999;
        assertEq(BoxV2(proxy).version(), 2, "BoxV2 should have version 2");
        assertEq(BoxV2(proxy).getValue(), expectedValue, "BoxV2 should have default number 999");

        uint256 newExpectedValue = 233;
        BoxV2(proxy).setValue(newExpectedValue);
        assertEq(BoxV2(proxy).getValue(), newExpectedValue, "BoxV2 should have new number 233");
    }
}
