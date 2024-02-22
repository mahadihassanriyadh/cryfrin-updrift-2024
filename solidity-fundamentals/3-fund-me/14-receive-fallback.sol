// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {PriceConverter} from "./library/PriceConverter.sol";

/* 
    -------------------------------------------------------------------------------------------------------------------------
    ------------------ What happens if someone sends this contract ETH without calling the fund function?? ------------------
    -------------------------------------------------------------------------------------------------------------------------
    - if someone directly sent any money to the contract's address we wouldn't be able to keep tract of those funders
    - so there are way we can trigger some code when someone sent some money in our contract without using the fund function
    - there are two special functions
        1. receive()
        2. fallback()ˇ
    
    ---------------------------------------
    -------------- receive() --------------
    ---------------------------------------
    - whenever an external payment is sent to the contract's address this receove func will get triggered
    - there can only be one receive function per contract
    - we can do something like this:
            receive() external payable { 
                updateFundersInfo();
            }
    NOTE: this will only get triggered if someone just sent a native currency without any data with it.

    ----------------------------------------
    -------------- fallback() --------------
    ----------------------------------------   
    - if some data were also sent with that function then solidity will think okay maybe the sender is trying to access a function
    - so the fallback() function will be triggered
    - see the implementation below

    - also we can normally deploy it in remix vm to test
    - to send ether just change the value in the address
    - to send data with transaction change the value in the CALLDATA input box
    - click 'Transact' to trigger a transaction 


    We can look into this beautiful illustrationn to understand more about these two functions:
    Which function is called, fallback() or receive()?

            send Ether
                |
            msg.data is empty?
                / \
                yes  no
                /     \
    receive() exists?  fallback()
            /   \
            yes   no
            /      \
        receive()   fallback()
*/

error DidNotSendMinEth();
error NotFundOwner();
error FundTransferFailed();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 5e18;

    bytes32 public testFallbackTrigger =
        0x746573744e756d00000000000000000000000000000000000000000000000000;
    int256 public testFallbackVar = 0;

    address chainlinkAggregatorV3InterfaceAddressEthUsd =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_fundOwner;

    constructor() {
        i_fundOwner = msg.sender;
    }

    function fund() public payable {
        if (msg.value.getConversionRate() < MIN_USD) {
            revert DidNotSendMinEth();
        }
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
            address funder = funders[funderIdx];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!callSuccess) {
            revert FundTransferFailed();
        }
    }

    modifier onlyOwner() {
        if (msg.sender != i_fundOwner) {
            revert NotFundOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
        if (bytes32(msg.data) == testFallbackTrigger) {
            testFallbackVar += 1;
        }
    }
}
