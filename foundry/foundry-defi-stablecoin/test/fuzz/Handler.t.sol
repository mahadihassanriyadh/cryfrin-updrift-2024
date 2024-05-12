// SPDX-License-Identifier: MIT
/*  
    [ANSI Regular](https://patorjk.com/software/taag/#p=display&f=ANSI%20Regular&t=Handler)
    ██   ██  █████  ███    ██ ██████  ██      ███████ ██████  
    ██   ██ ██   ██ ████   ██ ██   ██ ██      ██      ██   ██ 
    ███████ ███████ ██ ██  ██ ██   ██ ██      █████   ██████  
    ██   ██ ██   ██ ██  ██ ██ ██   ██ ██      ██      ██   ██ 
    ██   ██ ██   ██ ██   ████ ██████  ███████ ███████ ██   ██ 

    ⭐️ This file is used for handler based testing in foundry.
    In foundry there are two types of Invariant testing:
        - Open Testing
        - Handler-Based Testing (This is more helpful to test our invariants in a more controlled environment, which increases the chances of finding bugs in our invariants.)
*/

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DSCEngine engine;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    MockV3Aggregator ethUsdPriceFeed;
    MockV3Aggregator btcUsdPriceFeed;

    address[] public usersWithCollateralDeposited;
    uint256 public timesDepositCollateralIsCalled = 0;
    uint256 public timesRedeemCollateralIsCalled = 0;
    uint256 public timesMintIsCalled = 0;

    uint256 constant MAX_DEPOSIT_SIZE = type(uint96).max; // max value for uint96

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        engine = _engine;
        dsc = _dsc;

        address[] memory collateralTokens = engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        ethUsdPriceFeed = MockV3Aggregator(engine.getCollateralTokenPriceFeed(address(weth)));
        btcUsdPriceFeed = MockV3Aggregator(engine.getCollateralTokenPriceFeed(address(wbtc)));
    }

    // don't call redeemCollateral if there is no collateral
    function depositCollateral(uint256 _collateralSeed, uint256 _amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(_collateralSeed);
        // this bound function is a part of the forge-std library in StdUtils.sol
        // this function is used to bound the value of _amountCollateral between 1 and MAX_DEPOSIT_SIZE
        // so while running the fuzzer, the value of _amountCollateral will always be between 1 and MAX_DEPOSIT_SIZE
        _amountCollateral = bound(_amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, _amountCollateral);
        collateral.approve(address(engine), _amountCollateral);
        engine.depositCollateral(address(collateral), _amountCollateral);
        vm.stopPrank();
        
        // if(engine.getMaxMintableDscByUser(msg.sender) == 0) {
        //     usersWithCollateralDeposited.push(msg.sender);
        // }
        usersWithCollateralDeposited.push(msg.sender);

        timesDepositCollateralIsCalled++;
    }

    function redeemCollateral(uint256 _collateralSeed, uint256 _amountCollateral, uint256 _addressSeed) public {
        if(usersWithCollateralDeposited.length == 0) {
            return;
        }

        address sender = usersWithCollateralDeposited[_addressSeed % usersWithCollateralDeposited.length];

        ERC20Mock collateral = _getCollateralFromSeed(_collateralSeed);
        uint256 maxCollateralToRedeem = engine.getMaxCollateralToRedeem(sender, address(collateral));
        _amountCollateral = bound(_amountCollateral, 0, maxCollateralToRedeem);
        if (_amountCollateral == 0) {
            return;
        }

        // vm.assume not working as expected ❌
        // vm.assume(_amountCollateral != 0);

        vm.startPrank(sender);
        engine.redeemCollateral(address(collateral), _amountCollateral);
        vm.stopPrank();
        timesRedeemCollateralIsCalled++;

    }

    function mintDSC(uint256 _amount, uint256 _addressSeed) public {
        if(usersWithCollateralDeposited.length == 0) {
            return;
        }

        address sender = usersWithCollateralDeposited[_addressSeed % usersWithCollateralDeposited.length];

        int256 maxMintableDscByUser = engine.getMaxMintableDscByUser(sender);
        if (maxMintableDscByUser <= 0) {
            return;
        }

        _amount = bound(_amount, 0, uint256(maxMintableDscByUser));
        if (_amount == 0) {
            return;
        }

        vm.startPrank(sender);
        engine.mintDSC(_amount);
        vm.stopPrank();

        timesMintIsCalled++;
    }

    /*  
        // ❌ This code below breaks our invariant tests, however this lets us know our current system is prone to high flactuations in the price feed.abi
        // If the collateral price crashes, our current system will most likely break.

        function updateCollateralPrice(uint96 newPrice) public {
            int256 newPriceInt = int256(uint256(newPrice));
            if (newPrice%2 == 0) {
                ethUsdPriceFeed.updateAnswer(newPriceInt);
            } else {
                btcUsdPriceFeed.updateAnswer(newPriceInt);
            }
        }
    */
   
    /*  
        ##################################
        ######## Helper Functions ########
        ##################################
    */
    function _getCollateralFromSeed(uint256 _collateralSeed) private view returns (ERC20Mock) {
        if (_collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
