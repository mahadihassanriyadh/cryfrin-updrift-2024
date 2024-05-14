// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Proxy} from "@openzeppelin/proxy/Proxy.sol";

/**
 * @title SmallProxy2
 * 
 * @notice Here I personally tried to change some codes and tried to understand how the proxy works.
 * 
 */

contract SmallProxy2 is Proxy {
    // This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setImplementation(address newImplementation) public {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function _implementation() internal view override returns (address implementationAddress) {
        assembly {
            implementationAddress := sload(_IMPLEMENTATION_SLOT)
        }
    }

    // helper function
    function getDataToTransact(uint256 numberToUpdate) public pure returns (bytes memory) {
        return abi.encodeWithSignature("setValue(uint256)", numberToUpdate);
    }

    function readStorage() public view returns (uint256 valueAtStorageSlotZero) {
        assembly {
            valueAtStorageSlotZero := sload(0)
        }
    }
}

contract ImplementationA {
    uint256[] public values;

    function setValue(uint256 newValue) public {
        values.push(newValue);
    }
}

contract ImplementationB {
    uint256[] public values;

    function setValue(uint256 newValue) public {
        values.push(newValue);
        values.push(newValue + 5);
    }
}

contract ImplementationC {
    uint256 public check;
    uint256[] public values;

    function setValue(uint256 newValue) public {
        values.push(newValue);
        values.push(newValue + 5);
    }
}
