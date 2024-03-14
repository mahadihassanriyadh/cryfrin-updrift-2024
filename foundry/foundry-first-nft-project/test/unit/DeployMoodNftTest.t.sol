// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployMoodNft} from "../../script/DeployMoodNft.s.sol";
import {MoodNft} from "../../src/MoodNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployMoodNftTest is Test {
    DeployMoodNft public deployer;
    MoodNft public moodNft;
    address public USER = makeAddr("user");

    function setUp() public {
        deployer = new DeployMoodNft();
        moodNft = deployer.run();
    }

    function testConvertSvgToUri() public view {
        string
            memory svg = '<svg viewBox="0 0 200 200" width="400" height="400" xmlns="http://www.w3.org/2000/svg"><circle cx="100" cy="100" fill="yellow" r="78" stroke="black" stroke-width="3" /><g class="eyes"><circle cx="61" cy="82" r="12" /><circle cx="127" cy="82" r="12" /></g><path d="m136.81 116.53c.69 26.17-64.11 42-81.52-.73" style="fill:none; stroke: black; stroke-width: 3;" /></svg>';
        string memory uri = deployer.svgToImageURI(svg);
        console.log(uri);
    }
}
