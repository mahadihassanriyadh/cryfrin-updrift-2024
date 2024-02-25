// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract SimpleStorage {
    uint256 myFavNum; // 0

    uint256[] listOfFavNums; // []

    struct Person {
        uint256 favNum;
        string name;
    }

    Person[] public dynamicListOfPeople; // []

    function store(uint256 _favNum) public {
        myFavNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return myFavNum;
    }

    // string is a special type in solidity, that is why we need to specify the data location
    // data location can only be specified for special types, such as, array, struct or mapping types
    // uint256 is a premitive type but string is an array of bytes in solidity
    /* 
        Three (3) main places to store data in solidity:
        1. Memory (Temporary)
        2. Calldata (Temporary)
        3. Storage (Permanent)

        Memory vs Calldata: https://ethereum.stackexchange.com/questions/74442/when-should-i-use-calldata-and-when-should-i-use-memory

        Memory is useful for storing variables that are only needed temporarily during the execution of a function. These variables may include function arguments, local variables, and dynamic arrays that are created during the execution of a function.

        Calldata is useful for passing large amounts of data to a function without having to copy the data into memory, which can be expensive in terms of gas usage. By using calldata, you can avoid the overhead of copying data into memory and reduce the amount of gas needed to execute the function.

        One key difference between memory and calldata is that memory can be modified by the function, while calldata cannot. This means that if you want to modify a function argument, you must first copy it into memory. Here is an example:

            function addOne(uint[] calldata numbers) public pure returns (uint[] memory) {
            uint[] memory newNumbers = new uint[](numbers.length);
            for (uint i = 0; i < numbers.length; i++) {
                newNumbers[i] = numbers[i] + 1;
            }
            return newNumbers;
            }
        
        In summary, memory and calldata are both temporary data storage locations in Solidity, but they have important differences. Memory is used to hold temporary variables during function execution, while Calldata is used to hold function arguments passed in from an external caller. Calldata is read-only and cannot be modified by the function, while Memory can be modified. If you need to modify function arguments that are stored in calldata, you must first copy them into memory.
    */

    function addPerson(string memory _name, uint256 _favNum) public {
        dynamicListOfPeople.push( Person({name: _name, favNum: _favNum}) );
    }

    /* 
        Won't Work ❌
        function addPerson(string calldata _name, uint256 _favNum) public {
            _name = "Jakir";
            dynamicListOfPeople.push( Person({name: _name, favNum: _favNum}) );
        }

        Will Work ✅
        function addPerson(string memory _name, uint256 _favNum) public {
            _name = "Jakir";
            dynamicListOfPeople.push( Person({name: _name, favNum: _favNum}) );
        }
    */
}