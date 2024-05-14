// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BoxV1 is UUPSUpgradeable {
    uint256 internal number;

    function getNumber() external view returns (uint256) {
        return number;
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    /** 
     * @dev this function checks if the caller is authorized to upgrade the contract
     * this is where we usually implement those, onlyOwner or onlyAdmin checks
     * if we want this to be authorized by a DAO we can implement a modifier that checks if the caller is a DAO
     * 
     * @notice but for now we don't really care, anyone can upgrade this. So we will just leave it blank for now.
     * 
    */
    function _authorizeUpgrade(address newImplementation) internal override {}
}
