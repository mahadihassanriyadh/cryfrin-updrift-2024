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
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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
    error DSCEngine__HealthFactorTooLow(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk(uint256 healthFactor);
    error DSCEngine__HealthFactorNotImproved(uint256 healthFactor);
    error DSCEngine__NotEnoughDscMinted(uint256 totalDscMinted);
    error DSCEngine__NotEnoughCollateralDeposited();

    /*  
        ####################################
        ######## 🗂️ State Variables ########
        ####################################
    */
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // means we want to 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% bonus for liquidators

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
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

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
    /**
     *
     * @param _tokenCollateralAddress contract address of the token to deposit as collateral
     * @param _amountCollateral amount of collateral to deposit
     * @param _amountDscToMint amount of DSC to mint
     *
     * @notice this function will deposit your collateral and mint DSC in one transaction
     */
    function depositCollateralAndMintDSC(
        address _tokenCollateralAddress,
        uint256 _amountCollateral,
        uint256 _amountDscToMint
    ) external {
        depositCollateral(_tokenCollateralAddress, _amountCollateral);
        mintDSC(_amountDscToMint);
    }

    /**
     * @param _tokenCollateralAddress contract address of the token to redeem as collateral
     * @param _amountCollateral amount of collateral to redeem
     * @param _amountDscToBurn amount of DSC to burn
     *
     * @notice This function burns DSC and redeems underlying collateral in one transaction
     */
    function redeemCollateralForDSC(
        address _tokenCollateralAddress,
        uint256 _amountCollateral,
        uint256 _amountDscToBurn
    ) external {
        burnDSC(_amountDscToBurn);
        redeemCollateral(_tokenCollateralAddress, _amountCollateral);
        // redeemCollateral already checks the health factor, so we don't need to do it here
    }

    /**
     *
     * In order to redeem collateral:
     * health factor must be over 1 AFTER redeeming the collateral
     */
    function redeemCollateral(address _tokenCollateralAddress, uint256 _amountCollateral)
        public
        moreThanZero(_amountCollateral)
        nonReentrant
    {
        _redeemCollateral(_tokenCollateralAddress, _amountCollateral, msg.sender, msg.sender);

        // _redeemCollateral already checks the health factor, so we don't need to do it here
        // _revertIfHealthFactorIsBroken(msg.sender);
    }

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
        public
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
    function mintDSC(uint256 _amountDscToMint) public moreThanZero(_amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += _amountDscToMint;

        // we should check if they have minted too much ($150 DSC, $100 ETH)
        _revertIfHealthFactorIsBroken(msg.sender);

        bool minted = i_dsc.mint(msg.sender, _amountDscToMint);

        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    /**
     *
     * @param _amount The amount of DSC to burn
     *
     * @notice To burn DSC, we need to:
     * 1. Take the DSC from the user and bring it to this contract
     * 2. Burn the DSC from this contract
     */
    function burnDSC(uint256 _amount) public moreThanZero(_amount) {
        _burnDSC(_amount, msg.sender, msg.sender);
        // i don't think we need to check health factor here, because we are burning DSC, not minting
        // again just to be safe, we will keep it here for now
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     *
     * @param _collateral The address of the collateral token to liquidate
     * @param _user The address of the user to liquidate who has broken the health factor. Their health factor should be below MIN_HEALTH_FACTOR
     * @param _debtToCover The amount of DSC you want to burn to improve the user's health factor
     *
     * @notice This function allows anyone to liquidate a user who is undercollateralized
     * @notice This liquidate() function is a function which other users can call to remove people from the system who are undercollateralized to save the protocol.
     * @notice The function is saying: If someone is undercollateralized, we will pay you to liquidate them.
     * @notice you can partially liquidate a user
     * @notice you will get a liquidation bonus for taking the user's funds
     * @notice this function working assumes the protocol will be roughly 200% overcollateralized in order for this to work
     *
     * @notice A known bug would be if the protocol were 100% or less collateralized, then we wouldn't be able to incentivize liquidators
     * Because for example:
     * - I have $200 worth of ETH collateral
     * - I have $50 worth of DSC
     *
     * And we try to maintain 200% collateralization ratio
     *
     * Now suddenly, the price of ETH drops by 60%
     * - I have $80 worth of ETH collateral
     * - I have $50 worth of DSC
     *
     * As the collateralization ratio is 200%, my health factor is broken
     * A liquidator can come in and liquidate me and take my $80 worth of ETH by paying $50 worth of DSC
     * So the liquidator is getting $30 profit
     *
     * However if we were to maintain 100% collateralization ratio,
     * I wouldn't be undercollateralized, and the liquidator wouldn't liquidate me
     * But when I get undercollateralized, for exaple, I have $40 worth of ETH and $50 worth of DSC
     * The liquidator can liquidate me but he/she won't as he/she would be at a loss
     *
     */
    function liquidate(address _collateral, address _user, uint256 _debtToCover)
        external
        moreThanZero(_debtToCover)
        nonReentrant
    {
        // We always try to follow the checks-effects-interactions (CEI) pattern
        // 1. First check the health factor of the user, if the user is liquidatable
        uint256 startingUserHealthFactor = _healthFactor(_user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk(startingUserHealthFactor);
        }

        // 2. We want to burn their DSC to cover some of their debt
        // 3. We also want to take their collateral (basicually removing them from the system)

        // let's say, they have:
        // BAD USER: $140 ETH, $100 DSC
        // So their health factor should be broken as they are not maintaining 200% collateralization ratio
        // Now we can say, we wanna cover their debt of $100 DSC
        // debtToCover = $100
        // To do that we need to know how much that debt is worth in ETH,
        // $100 of DSC == ??? ETH?
        // so we need to figure out how much of the ETH or whatever collateral token are we getting for $100 of DSC debt
        // if the price of ETH is $2000, then we would get $100 / $2000 = 0.05 ETH
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(_collateral, _debtToCover);

        // 4. We also give 10% bonus to the liquidator
        // so we are giving the liquidator $110 worth of ETH for $100 worth of DSC
        // ⭐️ we should also implement a feature to liquidate in the event the protocol is insolvent
        // ⭐️ And sweep extra amounts into a treasury
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;

        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;

        // 5. We redeem the collateral from the user
        _redeemCollateral(_collateral, totalCollateralToRedeem, _user, msg.sender);

        // 6. We burn the DSC from the user
        _burnDSC(_debtToCover, _user, msg.sender);

        // 7. We check the health factor of the user again
        uint256 endingUserHealthFactor = _healthFactor(_user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved(endingUserHealthFactor);
        }

        // 8. We should also check, if it somehow broke the liquidator's health factor
        _revertIfHealthFactorIsBroken(msg.sender);
    }

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
    /**
     *
     * @param _amountDscToBurn The amount of DSC to burn
     * @param onBehalfOf The address of the user whose DSC is being burned
     * @param dscFrom The liquidator's address, who is paying the debt
     *
     * @dev low-level internal function, do not call unless the function calling it is checking the health factor
     */
    function _burnDSC(uint256 _amountDscToBurn, address onBehalfOf, address dscFrom) private {
        if(s_DSCMinted[onBehalfOf] < _amountDscToBurn) {
            revert DSCEngine__NotEnoughDscMinted(s_DSCMinted[onBehalfOf]);
        }
        s_DSCMinted[onBehalfOf] -= _amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), _amountDscToBurn);

        // this conditional is hypothetically unreachable, because if the transfer fails, the transferFrom function will revert
        // we are keeping it here just to be safe, in case the i_dsc contract has been implemented incorrectly
        if (!success) {
            revert DSCEngine__TransferFailed();
        }

        i_dsc.burn(_amountDscToBurn);
    }

    /**
     *
     * @param _tokenCollateralAddress The address of the token to redeem as collateral
     * @param _amountCollateral The amount of collateral to redeem
     * @param _from The address to redeem the collateral from
     * @param _to The address to send the collateral to
     *
     * @notice this is an internal function, which we can use to redeem collateral from anybody
     */
    function _redeemCollateral(address _tokenCollateralAddress, uint256 _amountCollateral, address _from, address _to)
        private
        moreThanZero(_amountCollateral)
    {
        // here we are relying on the solidity compiler a little bit as well
        // if someone tries to pull out more collateral than they have, then the transfer should fail or revert
        // For example I want to pull out $1000 however I only have $500 in the system
        // 500 - 1000 = -500, will REVERT ❌
        // This is only possible with newer versions of solidity with safemath built in
        if (s_collateralDeposited[_from][_tokenCollateralAddress] < _amountCollateral) {
            revert DSCEngine__NotEnoughCollateralDeposited();
        }
        s_collateralDeposited[_from][_tokenCollateralAddress] -= _amountCollateral;
        emit CollateralRedeemed(_from, _to, _tokenCollateralAddress, _amountCollateral);

        // we could calculate the health factor here, but which is gas inefficient
        // so we will do the transfer first, and then check the health factor
        // all will be revert anyway if the health factor is broken

        bool success = IERC20(_tokenCollateralAddress).transfer(_to, _amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }

        _revertIfHealthFactorIsBroken(msg.sender);
    }

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
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        // let, totalDscMinted = $100, collateralValueInUsd = $150
        // collateralAdjustedForThreshold = 150 * (50 / 100) = 75
        // return collateralValueInUsd / totalDscMinted = 75 / 100 = 0.75
        // So, the health factor is 0.75, User is UNDERCOLLATERALIZED!!!!!!!!! ❌
        // here collateralAdjustedForThreshold is in 18 decimal points, totalDscMinted is in 18 decimal points as well
        // So, if we didn't multiphy collateralAdjustedForThreshold by PRECISION (1e18), we would get a floating point number
        // And we can't have floating point numbers in solidity

        // let's consider another example
        // totalDscMinted = $100, collateralValueInUsd = $1000
        // collateralAdjustedForThreshold = 1000 * (50 / 100) = 500
        // return collateralValueInUsd / totalDscMinted = 500 / 100 = 5
        // So, the health factor is 5, User is OVERCOLLATERALIZED!!!!!!!!! ✅

        if (totalDscMinted <= 0) {
            return type(uint256).max;
        }
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    /**
     * @notice need to do two things here:
     * 1. Check health factor (do they have enough collateral to back their DSC?)
     * 2. revert if they don't
     */
    function _revertIfHealthFactorIsBroken(address _user) internal view {
        uint256 userHealthFactor = _healthFactor(_user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorTooLow(userHealthFactor);
        }
    }

    /*  
        ###########################################################
        ########### 📥 Public & External View Functions ###########
        ###########################################################
    */
    /**
     * @param _collateralToken The address of the collateral token (WETH, WBTC, etc.)
     * @param _usdAmmountInWei The amount in USD to convert to the token amount
     *
     * @return The amount of tokens needed to represent the USD amount
     *
     * To calculate the amount of tokens needed to represent the USD amount, we need to:
     * - Get the price feed of the token
     * - Calculate the amount of tokens needed to represent the USD amount
     *   For example:
     *   - 1 ETH = $2000, and we have $500 (_usdAmmountInWei)
     *   - So we would need 500 / 2000 = 0.25 ETH
     */
    function getTokenAmountFromUsd(address _collateralToken, uint256 _usdAmmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_collateralToken]);
        (, int256 price,,,) = priceFeed.latestRoundData();

        // ($500e18 * 1e18) / (($2000e8 * 1e10)
        return (_usdAmmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }
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

    function getAccountInfo(address _user) public view returns (uint256 totalDscMinted, uint256 collateralValueInUsd) {
        (totalDscMinted, collateralValueInUsd) = _getAccountInfo(_user);
    }
}
