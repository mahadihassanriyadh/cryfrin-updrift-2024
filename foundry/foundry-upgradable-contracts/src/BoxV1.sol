// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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

    /** 
     * @notice also there was a method in the openzeppelin UUPSUpgradeable contract on previous versions known as "Storage Gaps"
     * this is a reserved space in the contract storage that allows future versions to add new variables without shifting down storage in the inheritance chain.
     * 
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     * uint256[50] private __gap;
     * 
     * @notice But a better way has been implemented in the new versions
     * Now "Diamond Storage" is being used, instead of "Storage Gaps"
     * This is the PR that upgraded the storage layout to Diamond Storage: 
     *      https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2964
    */
}
