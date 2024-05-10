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

contract Handler is Test {
    DSCEngine engine;
    DecentralizedStableCoin dsc;

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        engine = _engine;
        dsc = _dsc;
    }

    // don't call redeemCollateral if there is no collateral
    function depositCollateral(address _collateralSeed, uint256 _amountCollateral) public {
        engine.depositCollateral(_collateralSeed, _amountCollateral);
    }

    /*  
        ##################################
        ######## Helper Functions ########
        ##################################
    */
}
