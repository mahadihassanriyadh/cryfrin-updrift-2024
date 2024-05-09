// SPDX-License-Identifier: MIT
/*  
    [ANSI Regular](https://patorjk.com/software/taag/#p=display&f=ANSI%20Regular&t=Invariants)
    ██ ███    ██ ██    ██  █████  ██████  ██  █████  ███    ██ ████████ ███████ 
    ██ ████   ██ ██    ██ ██   ██ ██   ██ ██ ██   ██ ████   ██    ██    ██      
    ██ ██ ██  ██ ██    ██ ███████ ██████  ██ ███████ ██ ██  ██    ██    ███████ 
    ██ ██  ██ ██  ██  ██  ██   ██ ██   ██ ██ ██   ██ ██  ██ ██    ██         ██ 
    ██ ██   ████   ████   ██   ██ ██   ██ ██ ██   ██ ██   ████    ██    ███████

    ⭐️ This file is used to track all our invariants and ensure they are always true.
    
    ❓ The question we should always ask ourselves is, what are our invariants?

        1. The total supply of DSC tokens should always be less than the total value of the collateral.
        2. Getter view functions should never revert <- evergreen invariant 🟢
*/

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();
        targetContract(address(engine));
    }

    // adding our invariant
    function invariant_protocolMustHaveMoreValueThanTotalCollateralSupply() public view {
        // get the value of all the collateral in the protocol
        // compare it to all the debt (dsc)
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(engine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(engine));

        uint256 wethValueInUsd = engine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValueInUsd = engine.getUsdValue(wbtc, totalWbtcDeposited);

        uint256 totalCollateralValue = wethValueInUsd + wbtcValueInUsd;

        console.log("Total Supply: ", totalSupply);
        console.log("Total Collateral Value: ", totalCollateralValue);

        assert(totalCollateralValue >= totalSupply);
    }
}
