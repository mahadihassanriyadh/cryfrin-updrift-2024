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
        console.log("owner: ", boxV1.owner());
        assertEq(boxV1.version(), 1, "BoxV1 should have version 1");
        assertEq(boxV1.getNumber(), 99, "BoxV1 should have default number 99");
    }

    function testUpgradeWorks() public {
        BoxV2 boxV2 = new BoxV2();

        console.log("BoxV2 Owner", boxV2.owner());
        console.log("Proxy Owner", BoxV1(proxy).owner());
        console.log("Msg Sender", msg.sender);
        console.log("prev number", BoxV1(proxy).getNumber());

        vm.prank(BoxV1(proxy).owner());
        BoxV1(proxy).transferOwnership(msg.sender);

        address proxy2 = upgrader.upgradeBox(proxy, address(boxV2));

        console.log("current number", BoxV2(proxy2).getNumber());
    }
}