// SPDX-License-Identifier: MIT

/*  
    ####################################################
    ####### Code Layout & Order (Style Guide) 🎨 #######
    ####################################################

    ⭕️ Contract Layout:
        - Pragma statements (Version)
        - Import statements
        - errors
        - Interfaces, Libraries, Contracts
        - Type declarations
        - State variables
        - Events
        - Modifiers
        - Functions

    ⭕️ Layout of Functions:
        - constructor
        - receive function (if exists)
        - fallback function (if exists)
        - external
        - public
        - internal
        - private
        - view & pure functions 
        - internal & private view & pure functions
        - external & public view & pure functions
*/

pragma solidity ^0.8.24;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Decentralized Stable Coin
 * @author Md. Mahadi Hassan Riyadh
 * Relative Stability: Pegged to USD
 * Minting: Algorithmic
 * Collateral: Exogenous (ETH & BTC)
 *
 * This is the contract meant to be governed by DSCEngine. This contract is just the ERC20 implementation of our stablecoin sytstem.
 * This contract will be a pure ERC20 token implementation with minting and burning without any logics.
 * The logics will be in a separate contract called DSCEngine.
 *
 * We want our contract to be 100% governed by the DSCEngine contract or engine.
 * And our Egnine will have all these logics or stuffs like minting, burning, collateral management, etc.
 * This contract is purely gonna be the token.
 *
 * Since we want our token to be 100% controlled by the engine, we want the tokens to be ownable as well.
 * Means we are gonna have onlyOwner modifier in our minting and burning functions.
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__AmmountMustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmmountExceedsBalance();
    error DecentralizedStableCoin__ZeroAddressCannotBeUsed();

    constructor() ERC20("Decentralized Stable Coin", "DSC") Ownable() {}

    /**
     * There are two functions we want our engine to own.
     *      burn()
     *      mint()
     *
     * burn()
     * in burn() function we are overriding the burn() function from ERC20Burnable contract.
     * That's why after our task is done, we call the actual burn() function from ERC20Burnable contract using super.burn(_amount).
     *
     * mint()
     * for mint() function, there is no mint() function in ERC20Burnable contract.
     * so we can simply implement our mint() function.
     * and call the _mint() function from ERC20 contract.
     */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmmountMustBeMoreThanZero();
        }
        if (_amount > balance) {
            revert DecentralizedStableCoin__BurnAmmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__ZeroAddressCannotBeUsed();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmmountMustBeMoreThanZero();
        }

        _mint(_to, _amount);
        return true;
    }
}
