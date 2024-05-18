// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    /**
     * @dev Initializes the contract with the following parameters:
     *
     * - `minDelay`: initial minimum delay in seconds for operations. Min delay of how much time is required to pass before a proposal can be executed.
     * - `proposers`: accounts to be granted proposer and canceller roles. List of addresses that can propose and cancel proposals.
     * - `executors`: accounts to be granted executor role. List of addresses that can execute proposals.
     * - `admin`: optional account to be granted admin role; disable with zero address
     *
     * IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
     * without being subject to delay, but this role should be subsequently renounced in favor of
     * administration through timelocked proposals. Previous versions of this contract would assign
     * this admin to the deployer automatically and should be renounced as well.
     */
    constructor(uint256 _minDelay, address[] memory _proposers, address[] memory _executors)
        TimelockController(_minDelay, _proposers, _executors, msg.sender)
    {}
}
