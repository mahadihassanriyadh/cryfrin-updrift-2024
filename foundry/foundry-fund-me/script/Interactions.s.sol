// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

// A Fund Script
// A Withdraw Script

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 5 ether;

    function fundFundMe(address _mostRecentDeployed) public {
        vm.startBroadcast();
        FundMe(payable(_mostRecentDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("FundMe Contract Funded with %s", SEND_VALUE);
    }

    function run() external {
        /* 
            we need to pass two arguments to get the most recent deployment
                1. the contract name
                2. the chain id to let the tool know which network to look for the deployment 

            What it basically does is:
                1. looks at our deployment folder based on the chain id
                2. picks up the run-latest
                3. and grabs the most recent deployed cntract in that file
  
        */
        address contractAddress = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(contractAddress);
    }
}

contract WithdrawFundMe is Script {}
