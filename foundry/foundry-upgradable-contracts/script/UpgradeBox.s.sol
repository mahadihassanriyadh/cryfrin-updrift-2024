// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {DevOpsTools} from "@foundry-devops/src/DevOpsTools.sol";

contract UpgradeBox is Script {
    // uint256 public constant DEFAUT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run() external returns (address) {
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);

        vm.startBroadcast();
        BoxV2 newBox = new BoxV2(); // new implementation contract (Logic)
        vm.stopBroadcast();

        address proxy = upgradeBox(mostRecentDeployed, address(newBox));
        return proxy;
    }

    function upgradeBox(address _proxyAddress, address _newBox) public returns (address) {
        vm.startBroadcast();
        BoxV1 proxy = BoxV1(_proxyAddress);
        proxy.upgradeToAndCall(address(_newBox), abi.encodeWithSignature("initialize()"));
        vm.stopBroadcast();

        return address(proxy);
    }
}
