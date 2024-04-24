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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error DSCEngine__TransferFailed();

    /*  
        ####################################
        ######## 🗂️ State Variables ########
        ####################################
    */
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    mapping(address token => address priceFeed) private s_priceFeeds; // Mapping of token address to price feed address
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; // Mapping of user address to mapping of token address to amount deposited
    mapping(address user => uint256 amountDSCMinted) private s_DSCMinted;
    address[] private s_collateralTokens; // Array of all collateral tokens

    DecentralizedStableCoin private immutable i_dsc; // The DSC token

    /*  
        ###################################
        ############ 🎃 Events ############
        ###################################
    */
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

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
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        // usd Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAndPriceFeedLengthMismatch();
        }

        // For exaple, ETH/USD, BTC/USD, MKR/USD, etc.
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /*  
        #############################################
        ########### 📥 External Functions ###########
        #############################################
    */
    function depositCollateralAndMintDSC() external {}

    function redeemCollateralForDSC() external {}

    /**
     * @param _tokenCollateralAddress The address of the token to deposit as collateral
     * @param _amountCollateral The amount of collateral to deposit
     *
     * @notice This function allows users to deposit collateral into the system in order to mint DSC.
     *
     * @notice nonReentrant modifier
     * we should always use the nonReentrant modifier to prevent reentrancy attacks, especially when dealing with external calls.
     * we will use nonReentrant modifier from OpenZeppelin's ReentrancyGuard contract.
     * this nonReentrant is a little gas intensive, but we should try to always use it when dealing with external calls just to be safe.
     *
     * @notice following the checks-effects-interactions (CEI) pattern.
     * The modifiers do the checks
     * Our effects are updating the state variables and emitting an event
     */
    function depositCollateral(address _tokenCollateralAddress, uint256 _amountCollateral)
        external
        moreThanZero(_amountCollateral)
        isAllowedToken(_tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][_tokenCollateralAddress] += _amountCollateral;
        emit CollateralDeposited(msg.sender, _tokenCollateralAddress, _amountCollateral);

        // Transfer the collateral from the user to this contract
        bool success = IERC20(_tokenCollateralAddress).transferFrom(msg.sender, address(this), _amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     * @notice Follows CEI
     * @param _amountDscToMint The amount of DSC to mint
     * @notice To mint DSC, we need to check if the collateral value > minimum threshold value of DSC
     */
    function mintDSC(uint256 _amountDscToMint) external moreThanZero(_amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += _amountDscToMint;

        // we should check if they have minted too much ($150 DSC, $100 ETH)
    }

    function redeemCollateral() external {}

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

    /*  
        ############################################################
        ########### 📥 Private & Internal View Functions ###########
        ############################################################
    */
    function _getAccountInfo(address _user)
        internal
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[_user];
        collateralValueInUsd = getAccountCollateralValueInUsd(_user);
    }

    /**
     * @param _user The address of the user to check the health factor of
     * This function returns how close to liquidation a user is.
     * If the health factor is below 1, the user is undercollateralized and should be liquidated.
     *
     * To perfom this calculation, we need:
     * - The value of all collateral
     * - The value of all DSC
     */
    function _healthFactor(address _user) internal view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInfo(_user);
    }

    function _revertIfHealthFactorIsBroken(address _user) internal view {
        // 1. Check health factor (do they have enough collateral to back their DSC?)
        // 2. revert if they don't
    }

    /*  
        ###########################################################
        ########### 📥 Public & External View Functions ###########
        ###########################################################
    */
    /**
     *
     * @param _user The address of the user to get the collateral value of
     * @return totalCollateralValueInUsd The value of all collateral in USD
     *
     * To calculate the value of all collateral in USD, we need to:
     * - Loop through all collateral tokens
     * - Get the amount of each token deposited by the user
     * - And map that to the price feed to get the USD value
     */
    function getAccountCollateralValueInUsd(address _user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[_user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }

        // we do not need to return here as we have explicitly named the returned variable while declaring the function, inside returns (uint256 totalCollateralValueInUsd)
        // return totalCollateralValueInUsd;
    }

    function getUsdValue(address _token, uint256 _amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // price is in 8 decimal places
        // so if 1 ETH = $1000, we would get 1000 * 10e8 here
        // now if we wanted to calculate the value, we couldn't simply do:
        //    price * amount (considering amount = 1 ETH = 1 * 1e18 wei)
        //    because that would mean (1000 * 1e8) * (1 * 1e18)
        // Which would return a massive number, and we can also see the units don't match up
        // price is in 8 decimals, whereas amount (eth) is in 18 decimals
        // so we need to match those as well
        // so let's first multiply price by 1e10
        //    (1000 * 1e8 * (1e10)) * (1 * 1e18)
        // And finally divide the whole thing by 1e18 as we were multiply 1e18 two times, one from price, one from amount
        // Diving with 1e18 would nullify the effect of one of the multiplication
        // So our returned value would be in 18 decimal points instead of 36
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * _amount) / PRECISION;
    }
}
