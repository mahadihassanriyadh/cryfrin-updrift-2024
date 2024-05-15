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
    address public OWNER = makeAddr("owner");

    address public proxy;

    BoxV1 public boxV1;

    function setUp() public {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();

        proxy = deployer.run(); // right now points to BoxV1
    }

    function testDeploy() public {
        boxV1 = BoxV1(proxy);
        assertEq(boxV1.version(), 1, "BoxV1 should have version 1");
        assertEq(boxV1.getValue(), 999, "BoxV1 should have default number 999");
    }

    function testUpgradeWorks() public {
        BoxV2 boxV2 = new BoxV2();

        vm.prank(BoxV1(proxy).owner());
        BoxV1(proxy).transferOwnership(msg.sender);

        address proxy2 = upgrader.upgradeBox(proxy, address(boxV2));
    }
}