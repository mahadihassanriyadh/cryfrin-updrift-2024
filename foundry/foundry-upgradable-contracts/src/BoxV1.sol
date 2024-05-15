// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
 *
 * @notice ⭐️⭐️⭐️ Initializable ⭐️⭐️⭐️
 *
 * Contructors are not used in Proxy contracts ❌
 * - Storage is stored in the proxy, not in the implementation contract
 * - We have Proxy which will direct our call to the implementation contract, and use code from the implementation contract and execute it in the context of the proxy.
 * - It's like the proxy is just borrowing the functions or code from the implementation contract and using it as its own.
 * - we don't want to use a constructor in our implementation because the Proxy doesn't call the constructor when a contract is initialized. Instead, we need to utilize an initializer function to replace the constructor logic.
 *
 * So the solution is ✅:
 * - With proxy first we need to deploy the implementation contract
 * - Then call some "initializer" function
 * - The "initializer" function is basically my constructor, except for this is gonna be called on the proxy.
 * - A function marked with the initializer modifier can be initialized only once. It's a way to define a constructor for contracts that are meant to be used via Proxy, without the typical Solidity constructor's downside.
 *
 */
contract BoxV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 internal value;

    /**
     * @notice ⭐️⭐️⭐️ _disableInitializers ⭐️⭐️⭐️
     * @dev ths _disableInitializers function Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call. Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized to any version. It is recommended to use this to lock implementation contracts that are designed to be called through proxies. (https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--)
     */
    // some linter may throw some error, as we are using a contructor in a proxy contract, thus the comment below is added to ignore the error
    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice ⭐️⭐️⭐️ initialize ⭐️⭐️⭐️
     * This is basically a constructor for proxy contracts.
     * This is our implementation contract. If we use constructor here, it will be executed in the context of the implementation contract, not the proxy contract.
     * So we use an initializer function instead of a constructor. Which will be called on the proxy contract.
     *
     * This __Ownable_init() is from the OwnableUpgradeable contract, which is used to set the owner of the contract.
     * This __UUPSUpgradeable_init() is from the UUPSUpgradeable contract, which is used to initialize the UUPSUpgradeable contract.
     *
     * @notice the initializer moifier is used to make sure that this function is called only once. Meaning, it won't be possible to call the initialize function again after it has been called once.
     */
    function initialize() public initializer {
        __Ownable_init(msg.sender); // this is essentially saying: owner = msg.sender; The diff is, instead of storing the owner in the implementation contract, it stores it in the proxy contract. Also the double underscore (__) is a convention to indicate that this is an initializer function.
        __UUPSUpgradeable_init(); // this basically does nothing, but it's best practice to have this in here, to say, Hey, this is a UUPS Upgradeable contract. We're gonna treat as such.
        value = 999;
    }

    function getValue() external view returns (uint256) {
        return value;
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    /**
     *
     * @notice ⭐️⭐️⭐️ _authorizeUpgrade() ⭐️⭐️⭐️
     * @dev this function checks if the caller is authorized to upgrade the contract
     * this is where we usually implement those, onlyOwner or onlyAdmin checks
     * if we want this to be authorized by a DAO we can implement a modifier that checks if the caller is a DAO
     *
     * @notice but for now we don't really care, anyone can upgrade this. So we will just leave it blank for now.
     *
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     *
     * @notice ⭐️⭐️⭐️ Storage Gaps ⭐️⭐️⭐️
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
