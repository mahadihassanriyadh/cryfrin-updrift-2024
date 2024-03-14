// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BasicNFT} from "../src/BasicNFT.sol";
import {MoodNft} from "../src/MoodNft.sol";

contract MintBasicNFT is Script {
    string public constant NIPPY =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "BasicNFT",
            block.chainid
        );
        mintNFTOnContract(mostRecentlyDeployed);
    }

    function mintNFTOnContract(address _contractAddress) public {
        vm.startBroadcast();
        BasicNFT(_contractAddress).mintNFT(NIPPY);
        vm.stopBroadcast();
    }
}

contract MintMoodNft is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MoodNft",
            block.chainid
        );
        mintNFTOnContract(mostRecentlyDeployed);
    }

    function mintNFTOnContract(address _contractAddress) public {
        vm.startBroadcast();
        MoodNft(_contractAddress).mintNft();
        vm.stopBroadcast();
    }
}

contract FlipMoodNft is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MoodNft",
            block.chainid
        );
        flipMoodOnContract(mostRecentlyDeployed);
    }

    function flipMoodOnContract(address _contractAddress) public {
        vm.startBroadcast();
        MoodNft(_contractAddress).flipMood(0);
        vm.stopBroadcast();
    }
}
