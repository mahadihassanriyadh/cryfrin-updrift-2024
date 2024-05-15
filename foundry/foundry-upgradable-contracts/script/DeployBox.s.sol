// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployBox is Script {
    // uint256 public constant DEFAUT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run() external returns (address) {
        address proxy = deployBox();
        return proxy;
    }

    function deployBox() public returns (address) {
        vm.startBroadcast();
        BoxV1 box = new BoxV1(); // implementation contract (Logic)

        ERC1967Proxy proxy = new ERC1967Proxy(address(box), abi.encodeWithSignature("initialize()")); // proxy contract
        /*  
            // We could also do this, instead of the above line
            ERC1967Proxy proxy = new ERC1967Proxy(address(box), abi.encodeWithSignature("")); // proxy contract
            BoxV1(address(proxy)).initialize();
        */
       
        vm.stopBroadcast();
        return address(proxy);
    }
}
