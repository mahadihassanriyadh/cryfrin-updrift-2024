// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract CallAnythig {
    address public s_someAddress;
    uint256 public s_amount;

    function transfer(address _someAddress, uint256 _amount) public {
        s_someAddress = _someAddress;
        s_amount = _amount;
    }
    
    /* 
        ###################################################
        ###### ⭐️ Function Selectors & Signatures ⭐️ ######
        ###################################################
        Solidity uses a 4 byte function selector to determine which function to call, this is generated from the function signature
        1. the first 4 bytes of the keccak256 hash of the function signature is the function selector
        2. the function signature is the function name and the parameter types

        We can get a function selector as easy as this:
            - "transfer(address,uint256)" is our function signature
            - and our resulting function selector of "transfer(address,uint256)" is output from this function
                bytes4(keccak256("transfer(address,uint256)"))
        
        NOTE: one thing to note here is that there shouldn't be any spaces in "transfer(address,uint256)" 
    */
    function getSelectorOne() public pure returns (bytes4 selector) {
        selector = bytes4(keccak256("transfer(address,uint256)"));
    }

    // this gives us all the data that we need to put in that data field of our transaction, to let this contract know, hey, go use the transfer function, pass in some address and then an amount.
    // so the bytes this function will return, we are going to put those bytes into the data field of our transaction, in order for us to call transfer from anywhere. So this is the bytes, this is the binary encoded data, which says, hey, call the transfer function with the address and amount that we specified with.
    function getDataToCallTransfer(
        address _someAddress,
        uint256 _amount
    ) public pure returns (bytes memory) {
        return abi.encodeWithSelector(getSelectorOne(), _someAddress, _amount);
    }

    function callTransferFunctionDirectly(
        address _someAddress,
        uint256 _amount
    ) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) = address(this).call(
            getDataToCallTransfer(_someAddress, _amount)
        );
        return (bytes4(returnData), success);
    }

    // Using encodeWithSignature
    // If we use encodeWithSignature, we don't need to encode the function selector ourselves, this abi.encodeWithSignature will do it for us
    // We just need to pass in the function signature and the parameters
    function callTransferFunctionDirectlyTwo(
        address someAddress,
        uint256 amount
    ) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                someAddress,
                amount
            )
        );
        return (bytes4(returnData), success);
    }

    // We can also get a function selector from data sent into the call
    function getSelectorTwo() public view returns (bytes4 selector) {
        bytes memory functionCallData = abi.encodeWithSignature(
            "transfer(address,uint256)",
            address(this),
            123
        );
        selector = bytes4(
            bytes.concat(
                functionCallData[0],
                functionCallData[1],
                functionCallData[2],
                functionCallData[3]
            )
        );
    }

    // Another way to get data (hard coded)
    function getCallData() public view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(this),
                123
            );
    }

    // Pass this:
    // 0xa9059cbb000000000000000000000000d7acd2a9fd159e69bb102a1ca21c9a3e3a5f771b000000000000000000000000000000000000000000000000000000000000007b
    // This is output of `getCallData()`
    // This is another low level way to get function selector using assembly
    // You can actually write code that resembles the opcodes using the assembly keyword!
    // This in-line assembly is called "Yul"
    // It's a best practice to use it as little as possible - only when you need to do something very VERY specific
    function getSelectorThree(
        bytes calldata functionCallData
    ) public pure returns (bytes4 selector) {
        // offset is a special attribute of calldata
        assembly {
            selector := calldataload(functionCallData.offset)
        }
    }

    // Another way to get your selector with the "this" keyword
    function getSelectorFour() public pure returns (bytes4 selector) {
        return this.transfer.selector;
    }

    // Just a function that gets the signature
    function getSignatureOne() public pure returns (string memory) {
        return "transfer(address,uint256)";
    }
}

contract CallFunctionWithoutContract {
    address public s_selectorsAndSignaturesAddress;

    constructor(address selectorsAndSignaturesAddress) {
        s_selectorsAndSignaturesAddress = selectorsAndSignaturesAddress;
    }

    // pass in 0xa9059cbb000000000000000000000000d7acd2a9fd159e69bb102a1ca21c9a3e3a5f771b000000000000000000000000000000000000000000000000000000000000007b
    // you could use this to change state
    function callFunctionDirectly(
        bytes calldata callData
    ) public returns (bytes4, bool) {
        (
            bool success,
            bytes memory returnData
        ) = s_selectorsAndSignaturesAddress.call(
                abi.encodeWithSignature("getSelectorThree(bytes)", callData)
            );
        return (bytes4(returnData), success);
    }

    // with a staticcall, we can have this be a view function!
    function staticCallFunctionDirectly() public view returns (bytes4, bool) {
        (
            bool success,
            bytes memory returnData
        ) = s_selectorsAndSignaturesAddress.staticcall(
                abi.encodeWithSignature("getSelectorOne()")
            );
        return (bytes4(returnData), success);
    }

    function callTransferFunctionDirectlyThree(
        address someAddress,
        uint256 amount
    ) public returns (bytes4, bool) {
        (
            bool success,
            bytes memory returnData
        ) = s_selectorsAndSignaturesAddress.call(
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    someAddress,
                    amount
                )
            );
        return (bytes4(returnData), success);
    }
}
