// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            ,
            ,
            ,
            uint256 _deployerKey
        ) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator, _deployerKey);
    }

    function createSubscription(
        address _vrfCoordinatorV2,
        uint256 _deployerKey
    ) public returns (uint64, address) {
        console.log("Creating subscription on chain Id: ", block.chainid);
        vm.startBroadcast(_deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinatorV2)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Created subscription with id: ", subId);
        console.log(
            "Please update the subscription id in the HelperConfig.s.sol file"
        );
        return (subId, _vrfCoordinatorV2);
    }

    function run() external returns (uint64, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address _vrfCoordinatorV2,
            ,
            uint64 _subscriptionId,
            ,
            address _link,
            uint256 _deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (_subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint64 updatedSubId, address updatedVRFv2) = createSub.run();
            _subscriptionId = updatedSubId;
            _vrfCoordinatorV2 = updatedVRFv2;
            console.log(
                "New SubId Created! ",
                _subscriptionId,
                "VRF Address: ",
                _vrfCoordinatorV2
            );
        }

        fundSubscription(
            _vrfCoordinatorV2,
            _subscriptionId,
            _link,
            _deployerKey
        );
    }

    function fundSubscription(
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        address _link,
        uint256 _deployerKey
    ) public {
        console.log("Funding subscription on Subcription Id: ", _subscriptionId);
        console.log("Using vrfCoordinator: ", _vrfCoordinatorV2);
        console.log("Using link token: ", _link);

        // anvil chain id: 31337
        if (block.chainid == 31337) {
            vm.startBroadcast(_deployerKey);
            // this fundSubscription() function only exists in the mock VRFCoordinatorV2Mock, not the real VRFCoordinatorV2
            VRFCoordinatorV2Mock(_vrfCoordinatorV2).fundSubscription(
                _subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            // real testnet or mainnet
            vm.startBroadcast(_deployerKey);
            // for now don't worry about the transferAndCall, we can come back to it after we have understood abi encoding
            LinkToken(_link).transferAndCall(
                _vrfCoordinatorV2,
                FUND_AMOUNT,
                abi.encode(_subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address _raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            ,
            uint256 _deployerKey
        ) = helperConfig.activeNetworkConfig();

        addConsumer(_raffle, vrfCoordinator, subscriptionId, _deployerKey);
    }

    function addConsumer(
        address _contractToAddToVrf,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        uint256 _deployerKey
    ) public {
        console.log("Adding consumer to raffle: ", _contractToAddToVrf);
        console.log("Using vrfCoordinator: ", _vrfCoordinator);
        console.log("Using subscriptionId: ", _subscriptionId);
        console.log("Using chain id: ", block.chainid);

        vm.startBroadcast(_deployerKey);
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(
            _subscriptionId,
            _contractToAddToVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
