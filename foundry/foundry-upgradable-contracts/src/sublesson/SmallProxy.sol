// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

/**
 * @title SmallProxy
 * 
 * @notice If we look into the contract Proxy.sol from OpenZeppelin, we will see there is a fallback() and a receive() function.
 * And both of them call the _fallback() function.
 * Then the _fallback() function calls the _delegate() function, which is the one that actually calls the implementation.
 * 
 * @notice So, whenever we call a function on the proxy, if it is not setImplementation() function it will call the implementation contract that is on the _IMPLEMENTATION_SLOT.
 * 
 * @notice We tend to avoid storing any info in the proxy contract, as changes to the storage layout of the implementation contract can result in unexpected behavior in proxy.
 * @notice To tackle this was there was a proposal for a new proxy standard called UUPS (Universal Upgradeable Proxy Standard).
 * @notice Which is ERC-1967
 * This is a simple implementation for proxies, which provides a consistent location where proxies store the address of the logic contract they delegate to, as well as other proxy-specific information.
 * 
 * @notice This logic/implementation contract address is stored in a specific storage slot, which can be obtaned by:
 * bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1))
 * 
 * @notice This contract also uses a lot of assembly code, or more specifically Yul (inline assembly).
 * Yul is an aintermediate language that can be compiled to bytecode for different backends.
 * It's a sort of inline assembly and allows to write really, really low level codes, close to opcodes.
 * 
 */

contract SmallProxy is Proxy {
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
    uint256 public value;

    function setValue(uint256 newValue) public {
        value = newValue;
    }
}

contract ImplementationB {
    uint256 public value;

    function setValue(uint256 newValue) public {
        value = newValue + 2;
    }
}

// function setImplementation(){}
// Transparent Proxy -> Ok, only admins can call functions on the proxy
// anyone else ALWAYS gets sent to the fallback contract.

// UUPS -> Where all upgrade logic is in the implementation contract, and
// you can't have 2 functions with the same function selector.
