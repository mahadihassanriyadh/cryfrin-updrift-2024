// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BasicNFT} from "../src/BasicNFT.sol";

contract MintBasicNFT is Script {
    string public constant NIPPY1 =
        "ipfs://QmQKfTbGSN1XCYG6djwc4LNq8op5zbVxGzv7Vt8nzU7HGr/2974.json";
    string public constant NIPPY2 =
        "ipfs://QmQKfTbGSN1XCYG6djwc4LNq8op5zbVxGzv7Vt8nzU7HGr/1792.json";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "BasicNFT",
            block.chainid
        );
        mintNFTOnContract(mostRecentlyDeployed);
    }

    function mintNFTOnContract(address _contractAddress) public {
        vm.startBroadcast();
        BasicNFT(_contractAddress).mintNFT(NIPPY1);
        vm.stopBroadcast();
    }
}
