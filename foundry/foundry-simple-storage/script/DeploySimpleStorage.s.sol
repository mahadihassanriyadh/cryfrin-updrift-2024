// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {console} from "forge-std/test.sol";

contract DeploySimpleStorage is Script {
    function run() external virtual returns (SimpleStorage) {
        // before zksync
        // vm.startBroadcast();
        // SimpleStorage simpleStorage = new SimpleStorage();
        // vm.stopBroadcast();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying from address:", deployer);

        // Create the deployment bytecode first
        bytes memory bytecode = type(SimpleStorage).creationCode;
        address deployedAddress;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy using assembly with explicit bytecode handling
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(deployedAddress) { revert(0, 0) }
        }

        SimpleStorage simpleStorage = SimpleStorage(deployedAddress);
        vm.stopBroadcast();

        console.log("SimpleStorage deployed to:", address(simpleStorage));

        return simpleStorage;
    }
}
