// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployMoodNft} from "../../script/DeployMoodNft.s.sol";
import {MoodNft} from "../../src/MoodNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNftTest is Test {
    DeployMoodNft public deployer;
    MoodNft public moodNft;
    address public USER = makeAddr("user");

    function setUp() public {
        deployer = new DeployMoodNft();
        moodNft = deployer.run();
    }

    function testImageUriSetSuccessfully() public {
        string memory expectedHappySvgImgUri = deployer.svgToImageURI(
            vm.readFile("./images/dynamicNft/happy.svg")
        );
        string memory expectedSadSvgImgUri = deployer.svgToImageURI(
            vm.readFile("./images/dynamicNft/sad.svg")
        );

        string memory happySvgImgUri = moodNft.getHappySvgImgUri();
        string memory sadSvgImgUri = moodNft.getSadSvgImgUri();

        assertEq(
            keccak256(bytes(happySvgImgUri)),
            keccak256(bytes(expectedHappySvgImgUri))
        );
        assertEq(
            keccak256(bytes(sadSvgImgUri)),
            keccak256(bytes(expectedSadSvgImgUri))
        );
    }

    function testViewTokenURI() public {
        vm.prank(USER);
        moodNft.mintNft();
        console.log(moodNft.tokenURI(0));
    }
}
