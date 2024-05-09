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

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract InvariantsTest is StdInvariant, Test {}
