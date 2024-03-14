// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployMoodNft is Script {
    MoodNft public moodNft;
    address public USER = makeAddr("user");

    function run() external returns (MoodNft) {
        /*  
            #########################################
            ########### 🗂️ vm.readfile() ############
            #########################################
            - vm.readfile() is another cheat code given by foundry to access the file system.
            - to use this command we need to give foundry access to the file system by editing the foundry.toml file.
            - we should add the line below to the foundry.toml file:
                fs_permissions = [
                    { access = "read", path = "./images" },
                ]
        */
        string memory happySvgImgUri = svgToImageURI(
            vm.readFile("./images/dynamicNft/happy.svg")
        );
        string memory sadSvgImgUri = svgToImageURI(
            vm.readFile("./images/dynamicNft/sad.svg")
        );

        vm.startBroadcast();
        moodNft = new MoodNft({
            _name: "MoodNft",
            _symbol: "MOOD",
            _sadSvgImgUri: sadSvgImgUri,
            _happySvgImgUri: happySvgImgUri
        });
        vm.stopBroadcast();

        return moodNft;
    }

    function svgToImageURI(
        string memory _svg
    ) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(_svg));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }
}
