// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployBasicNFT} from "../script/DeployBasicNFT.s.sol";
import {BasicNFT} from "../src/BasicNFT.sol";

contract BasicNFTTest is Test {
    DeployBasicNFT public deployer;
    BasicNFT public basicNFT;
    address public USER = makeAddr("user");
    string public constant NIPPY1 = "ipfs://QmQKfTbGSN1XCYG6djwc4LNq8op5zbVxGzv7Vt8nzU7HGr/2974.json";
    string public constant NIPPY2 = "ipfs://QmQKfTbGSN1XCYG6djwc4LNq8op5zbVxGzv7Vt8nzU7HGr/1792.json";

    function setUp() public {
        deployer = new DeployBasicNFT();
        basicNFT = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "Nippy";
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
        // Mint the first NFT and assign it to USER
        basicNFT.mintNFT(NIPPY1);

        vm.prank(USER);
        // Mint the second NFT and assign it to USER
        basicNFT.mintNFT(NIPPY2);

        // Check that USER now owns 2 NFTs
        assert(basicNFT.balanceOf(USER) == 2);

        // Check that the token URI of the first NFT is correct
        assert(keccak256(abi.encodePacked(basicNFT.tokenURI(0))) == keccak256(abi.encodePacked(NIPPY1)));

        // Check that the token URI of the second NFT is correct
        assert(keccak256(abi.encodePacked(basicNFT.tokenURI(1))) == keccak256(abi.encodePacked(NIPPY2)));
    }
}
 