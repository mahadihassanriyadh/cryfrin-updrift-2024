// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

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
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant MAX_DSC_MINT_BY_USER = 12500 ether; // 50% of collateral value, here 12,5000 ether meaning 12,500 DSC ~ 12,500 USD
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
        engine.mintDSC(MAX_DSC_MINT_BY_USER);
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
        uint256 collateralThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        uint256 expectedHealthFactor = (collateralThreshold * PRECISION) / dscToMint;
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__HealthFactorTooLow.selector, expectedHealthFactor));
        engine.mintDSC(dscToMint);
        vm.stopPrank();
    }

    function testCanMintDSCAndGetAccountInfo() public depositedCollateral mintedDSC {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInfo(USER);
        uint256 expectedTotalDscMinted = MAX_DSC_MINT_BY_USER;
        uint256 expectedCollateralValue = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        assertEq(collateralValueInUsd, expectedCollateralValue, "Collateral value in USD should be 25000");
        assertEq(totalDscMinted, expectedTotalDscMinted, "Total DSC minted should be 12500");
    }

    /*  
        ###################################
        ######## Redeem Collateral ########
        ###################################
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
}
