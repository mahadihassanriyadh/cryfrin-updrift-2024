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

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine engine;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 constant MAX_DEPOSIT_SIZE = type(uint96).max; // max value for uint96

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        engine = _engine;
        dsc = _dsc;

        address[] memory collateralTokens = engine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // don't call redeemCollateral if there is no collateral
    function depositCollateral(uint256 _collateralSeed, uint256 _amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(_collateralSeed);
        _amountCollateral = bound(_amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, _amountCollateral);
        collateral.approve(address(engine), _amountCollateral);
        engine.depositCollateral(address(collateral), _amountCollateral);
        vm.stopPrank();
    }

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
