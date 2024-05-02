// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../../test/mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant MAX_DSC_MINT_BY_USER = 12500 ether; // 50% of collateral value, here 12,5000 ether meaning 12,500 DSC ~ 12,500 USD
    uint256 public constant INITIAL_DSC_MINT = 10000 ether; // means 8,000 DSC ~ 8,000 USD, ether is just another way of writing wei or 1e18
    uint256 public constant LIQUIDATION_THRESHOLD = 50; // means we want to 200% overcollateralized
    uint256 public constant LIQUIDATION_PRECISION = 100;
    uint256 public constant PRECISION = 1e18;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /*  
        #####################################
        ######## 🧱 Constructor Test ########
        #####################################
    */
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLenDoesntMatchPriceFeedLen() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);
        vm.expectRevert(DSCEngine.DSCEngine__TokenAndPriceFeedLengthMismatch.selector);
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /*  
        #####################################
        ######## 💰 Price Feed Tests ########
        #####################################
    */
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        // 15e18 * 2500/ETH = 37500e18 USD
        uint256 expectedUsdValue = 37500e18;
        uint256 actualUsdValue = engine.getUsdValue(weth, ethAmount);
        assertEq(actualUsdValue, expectedUsdValue, "USD value of 15 ETH should be 37500");

        uint256 btcAmount = 2e8;
        // 2e8 * 65000/BTC = 130000e8
        expectedUsdValue = 130000e8;
        actualUsdValue = engine.getUsdValue(wbtc, btcAmount);
        assertEq(actualUsdValue, expectedUsdValue, "USD value of 2 BTC should be 130000");
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 37500 ether;
        // 37500e18 / 2500/ETH = 15e18 ETH
        uint256 expectedTokenAmount = 15 ether;
        uint256 actualTokenAmount = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(actualTokenAmount, expectedTokenAmount, "Token amount of 37500 USD should be 15 ETH");
    }

    /*  
        ##########################################
        ######## Deposit Collateral Tests ########
        ##########################################
    */
    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testRevertsIfCollateralAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__AmmountMustBeMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollteral() public {
        ERC20Mock randomToken = new ERC20Mock("Random", "RND", USER, AMOUNT_COLLATERAL);

        vm.startPrank(USER);
        ERC20Mock(randomToken).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(randomToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInfo(USER);
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedCollateralValue = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        assertEq(totalDscMinted, expectedTotalDscMinted, "Total DSC minted should be 0");
        assertEq(collateralValueInUsd, expectedCollateralValue, "Collateral value in USD should be 25000");
    }

    /*  
        ################################
        ######## Mint DSC Tests ########
        ################################
    */
    modifier mintedDSC() {
        vm.startPrank(USER);
        engine.mintDSC(INITIAL_DSC_MINT);
        vm.stopPrank();
        _;
    }

    function testRevertsIfCollateralValueIsZero() public {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__AmmountMustBeMoreThanZero.selector);
        engine.mintDSC(0);
        vm.stopPrank();
    }

    function testMintRevertsIfHealthFactorBreaks() public depositedCollateral {
        (, uint256 collateralValueInUsd) = engine.getAccountInfo(USER);
        vm.startPrank(USER);
        uint256 dscToMint = MAX_DSC_MINT_BY_USER + 1 ether;
        (uint256 expectedHealthFactor) = calculateHealthFactor(collateralValueInUsd, dscToMint);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__HealthFactorTooLow.selector, expectedHealthFactor));
        engine.mintDSC(dscToMint);
        vm.stopPrank();
    }

    function testCanMintDSCAndGetAccountInfo() public depositedCollateral mintedDSC {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInfo(USER);
        uint256 expectedTotalDscMinted = INITIAL_DSC_MINT;
        uint256 expectedCollateralValue = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        assertEq(collateralValueInUsd, expectedCollateralValue, "Collateral value in USD should be 25000");
        assertEq(totalDscMinted, expectedTotalDscMinted, "Total DSC minted should be 12500");
    }

    /*  
        #####################################################
        ######## Deposit Collateral & Mint DSC Tests ########
        #####################################################
    */
    modifier depositedCollateralAndMintedDSC() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, INITIAL_DSC_MINT);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndMintDsc() public depositedCollateralAndMintedDSC {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInfo(USER);
        uint256 expectedTotalDscMinted = INITIAL_DSC_MINT;
        uint256 expectedCollateralValue = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        assertEq(collateralValueInUsd, expectedCollateralValue, "Collateral value in USD should be 25000");
        assertEq(totalDscMinted, expectedTotalDscMinted, "Total DSC minted should be 12500");
    }

    /*  
        #########################################
        ######## Redeem Collateral Tests ########
        #########################################
    */
    function testCantRedeemZeroCollateral() public {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__AmmountMustBeMoreThanZero.selector);
        engine.redeemCollateral(weth, 0);
        vm.stopPrank();
    }

    function testCantRedeemCollateralBeforeMintIfNotEnoughCollateralDeposited() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotEnoughCollateralDeposited.selector);
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL + 1);
        vm.stopPrank();
    }

    function testCantRedeemCollateralIfHealthFactorBreaks() public depositedCollateral mintedDSC {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInfo(USER);
        vm.startPrank(USER);
        /*  
            - Collateral value = 10 ETH = 10 * 2500 = 25,000 USD
            - Total DSC minted = 10,000 DSC = 10,000 USD
            - To maintain 200% collateralization, we have to keep at least, (Total DSC minted * 2 = 20,000 USD)
            - So, we can redeem 5,000 USD worth of collateral without breaking the health factor
            - But here we are trying to redeem 5,250 USD worth of collateral, 
        */
        uint256 collateralAfterRedeem = collateralValueInUsd - engine.getUsdValue(weth, 2.1 ether);
        uint256 expectedHealthFactor = calculateHealthFactor(collateralAfterRedeem, totalDscMinted);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__HealthFactorTooLow.selector, expectedHealthFactor));
        engine.redeemCollateral(weth, 2.1 ether);
        vm.stopPrank();
    }

    function testCanRedeemCollateral() public depositedCollateral mintedDSC {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInfo(USER);
        uint256 collateralToRedeem = 2 ether;
        uint256 expectedCollateralValue = collateralValueInUsd - engine.getUsdValue(weth, collateralToRedeem);
        uint256 expectedHealthFactor = calculateHealthFactor(expectedCollateralValue, totalDscMinted);
        vm.startPrank(USER);
        engine.redeemCollateral(weth, collateralToRedeem);
        vm.stopPrank();
        (uint256 actualTotalDscMinted, uint256 actualCollateralValueInUsd) = engine.getAccountInfo(USER);
        uint256 actualHealthFactor = calculateHealthFactor(actualCollateralValueInUsd, actualTotalDscMinted);
        assertEq(actualCollateralValueInUsd, expectedCollateralValue, "Collateral value in USD should be 23000");
        assertEq(actualTotalDscMinted, totalDscMinted, "Total DSC minted should be 12500");
        assertEq(expectedHealthFactor, actualHealthFactor, "Health factor should be 200%");
    }

    /*  
        ###############################
        ######## Burn DSC Test ########
        ###############################
    */
    function testBurnDscRevertsIfAmountIsZero() public depositedCollateral mintedDSC {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__AmmountMustBeMoreThanZero.selector);
        engine.burnDSC(0);
        vm.stopPrank();
    }

    function testBurnDscRevertsIfNotEnoughDscMinted() public depositedCollateral mintedDSC {
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__NotEnoughDscMinted.selector, INITIAL_DSC_MINT));
        engine.burnDSC(MAX_DSC_MINT_BY_USER);
        vm.stopPrank();
    }

    function testCanBurn() public depositedCollateral mintedDSC {
        uint256 dscToBurn = 5000 ether;
        console.log("Total Supppplyyyyyy", dsc.totalSupply());
        uint256 expectedTotalDscMinted = INITIAL_DSC_MINT - dscToBurn;
        uint256 expectedCollateralValue = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        dsc.approve(address(engine), dscToBurn);
        engine.burnDSC(dscToBurn);
        vm.stopPrank();
        (uint256 actualTotalDscMinted, uint256 actualCollateralValueInUsd) = engine.getAccountInfo(USER);
        assertEq(actualTotalDscMinted, expectedTotalDscMinted, "Total DSC minted should be 7500");
        assertEq(actualCollateralValueInUsd, expectedCollateralValue, "Collateral value in USD should be 25000");
    }

    /*  
        ##################################
        ######## Liquidate Tests #########
        ##################################
    */
    modifier liquidator() {
        ERC20Mock(weth).mint(LIQUIDATOR, STARTING_ERC20_BALANCE * 10);
        vm.startPrank(LIQUIDATOR);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL * 10);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL * 10);
        engine.mintDSC(INITIAL_DSC_MINT);
        vm.stopPrank();
        _;
    }

    function testLiquidateRevertsIfHealthFactorIsGood() public depositedCollateral mintedDSC liquidator {
        vm.startPrank(LIQUIDATOR);
        uint256 userHealthFactor = engine.getHealthFactor(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__HealthFactorOk.selector, userHealthFactor));
        engine.liquidate(weth, USER, 6000 ether); // liquidator is trying to liquidate 6000 USD worth of DSC
        vm.stopPrank();
    }

    function testCanLiquidate() public depositedCollateral mintedDSC liquidator {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, INITIAL_DSC_MINT);
        vm.stopPrank();
        int256 ethUsdUpdatedPrice = 180e8; // 1 ETH = $180
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);

        // uint256 userHealthFactor = engine.getHealthFactor(USER);
        // console.log("User Health Factor", userHealthFactor);
        // uint256 liquidateAmount = 2000 ether;
        // vm.startPrank(address(engine));
        // ERC20Mock(weth).approve(LIQUIDATOR, liquidateAmount * 10);
        // vm.startPrank(LIQUIDATOR);
        // engine.liquidate(weth, USER, 1 ether); // liquidator is trying to liquidate 6000 USD worth of DSC
        // vm.stopPrank();
    }

    /*  
        ##################################
        ######## Helper Functions ########
        ##################################
    */
    function calculateHealthFactor(uint256 _collateralValueInUsd, uint256 _totalDscMinted)
        public
        pure
        returns (uint256)
    {
        if (_totalDscMinted == 0) {
            return type(uint256).max;
        }
        uint256 collateralThreshold = (_collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralThreshold * PRECISION) / _totalDscMinted;
    }
}
