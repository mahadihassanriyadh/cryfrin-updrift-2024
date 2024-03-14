// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployMoodNft} from "../script/DeployMoodNft.s.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNftTest is Test {
    DeployMoodNft public deployMoodNft;
    MoodNft public moodNft;
    address public USER = makeAddr("user");

    function setUp() public {
        deployMoodNft = new DeployMoodNft();
        moodNft = deployMoodNft.run();
    }

    function testViewTokenURI() public {
        vm.prank(USER);
        moodNft.mintNft();
        console.log(moodNft.tokenURI(0));
    }
}
