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

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
 * Our DSC system should always be "overcollateralized". At no point, should the value of all collateral <= the $ backed value of all DSC.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system, but is much simpler and has no governance or fees.
 */
contract DSCEngine is ReentrancyGuard {
    /*  
        ####################################
        ############# ❌ Erros #############
        ####################################
    */
    error DSCEngine__AmmountMustBeMoreThanZero();
    error DSCEngine__TokenAndPriceFeedLengthMismatch();
    error DSCEngine__TokenNotAllowed();

    /*  
        ####################################
        ######## 🗂️ State Variables ########
        ####################################
    */
    mapping(address token => address priceFeed) private s_priceFeeds; // Mapping of token address to price feed address

    DecentralizedStableCoin private immutable i_dsc; // The DSC token

    /*  
        ####################################
        ########### 📝 Modifiers ###########
        ####################################
    */
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__AmmountMustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address _token) {
        if (s_priceFeeds[_token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    /*  
        ####################################
        ########### 📥 Functions ###########
        ####################################
    */
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        // usd Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAndPriceFeedLengthMismatch();
        }

        // For exaple, ETH/USD, BTC/USD, MKR/USD, etc.
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    function depositCollateralAndMintDSC() external {}

    function redeemCollateralForDSC() external {}

    /**
     * @param _tokenCollateralAddress The address of the token to deposit as collateral
     * @param _amountCollateral The amount of collateral to deposit
     *
     * @notice This function allows users to deposit collateral into the system in order to mint DSC.
     *
     * we should always use the nonReentrant modifier to prevent reentrancy attacks, especially when dealing with external calls.
     * we will use nonReentrant modifier from OpenZeppelin's ReentrancyGuard contract.
     * this nonReentrant is a little gas intensive, but we should try to always use it when dealing with external calls just to be safe.
     */
    function depositCollateral(
        address _tokenCollateralAddress,
        uint256 _amountCollateral
    )
        external
        moreThanZero(_amountCollateral)
        isAllowedToken(_tokenCollateralAddress)
        nonReentrant
    {}

    function redeemCollateral() external {}

    function mintDSC() external {}

    function burnDSC() external {}

    /*  
        For exaple, I have:
        - $100 worth of ETH collateral
        - $50 worth of DSC

        But suddenly, the price of ETH drops by 60%.
        Now, I have:
        - $40 worth of ETH collateral
        - $50 worth of DSC

        I am undercollateralized by $10.
        I need to liquidate some DSC to get back to a safe position.
        Or the system should have a checking mechanism to liquidate my DSC, if I am undercollateralized, to save the system.
        Even in some scenarios, I can get kicked out of the system.

        This liquidate() function is a function which other users can call to remove people from the system who are undercollateralized to save the protocol.
    */
    function liquidate() external {}

    /*  
        There should be a health factor to know the health of the system or protocol.

        Again back to our previous example:
        I had:
        - $100 worth of ETH collateral
        - $50 worth of DSC

        We set a threshold of 150% maximum collateralization ratio.
        Now I have, let's say:
        - $74 worth of ETH collateral
        - $50 worth of DSC
        I am UNDERCOLLATERALIZED!!!!!!!!!

        Now, someone can call the liquidate() function to liquidate my DSC to save the system.
        - Someone will say, I'll pay back the $50 DSC and get all your Collateral (ETH).
        - So that someone is getting $74 worth of ETH by paying $50 DSC.
        - He/she is getting $24 profit.
        - And I am out of the system.
        - This is my punishment for being undercollateralized. 
    */
    function getHealthFacoctor() external view {}
}
