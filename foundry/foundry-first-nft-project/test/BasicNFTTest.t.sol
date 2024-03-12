// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployBasicNFT} from "../script/DeployBasicNFT.s.sol";
import {BasicNFT} from "../src/BasicNFT.sol";

contract BasicNFTTest is Test {
    DeployBasicNFT public deployer;
    BasicNFT public basicNFT;
    address public USER = makeAddr("user");
    string public constant PUG = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function setUp() public {
        deployer = new DeployBasicNFT();
        basicNFT = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "Cowie";
        string memory actualName = basicNFT.name();

        // as strings are arrays of bytes, we can't compare them directly
        /*  
            ##########################################
            ####### 🟰 Comparing two strings #########
            ##########################################
            1. Convert the strings to bytes.
                bytes memory encodedString = abi.encodePacked(string);
            2. Convert the bytes to bytes32/hash.
                keccak256(encodedString);
            3. Compare the bytes32/hash
                keccak256(encodedString) == keccak256(encodedString);
        */
        bytes memory expectedEncodedName = abi.encodePacked(expectedName);
        bytes memory actualEncodedName = abi.encodePacked(actualName);
        bytes32 expectedHash = keccak256(expectedEncodedName);
        bytes32 actualHash = keccak256(actualEncodedName);

        assert(expectedHash == actualHash);
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        basicNFT.mintNFT(PUG);

        assert(basicNFT.balanceOf(USER) == 1);
        assert(keccak256(abi.encodePacked(basicNFT.tokenURI(0))) == keccak256(abi.encodePacked(PUG)));
    }
}
