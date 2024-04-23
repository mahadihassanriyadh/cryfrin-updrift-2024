// SPDX-License-Identifier: MIT

/*  
    ####################################################
    ####### Code Layout & Order (Style Guide) 🎨 #######
    ####################################################

    ⭕️ Contract Layout:
        - Pragma statements (Version)
        - Import statements
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
*/

pragma solidity ^0.8.24;

/**
 * @title DSCEngine
 * @author Md. Mahadi Hassan Riyadh
 * 
 * 
 * This system is designed to be as minimal as possible, and haev the token maintain a 1 token =  $1 peg.
 * This stablecoin has the properties:
 * - Dollar Pegged
 * - Algorithmically Stable
 * - Exogenous Collateral
 * 
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by wBTC and wETH.
 * 
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system, but is much simpler and has no governance or fees.
 */ 
contract DSCEngine {

}