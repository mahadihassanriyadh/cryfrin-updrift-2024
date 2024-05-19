## Verify a transaction in MetaMask

We are trying to send a transaction to the blockchain using MetaMask. A window pops up asking us to confirm the transaction. We go to the HEX tab and at the end we will see something like this:
```
0x23b872dd000000000000000000000000ad1c737896cd841766bed18dd052d8244331e1db000000000000000000000000ad1c737896cd841766bed18dd052d8244331e1db0000000000000000000000000000000000000000000000000000000005f5e100
```

We can use this data to check if metamask is actually calling the right function in the smart contract. To do this we can use foundry cast, we can see all the cast related command with:
```bash
cast --help
```

If we type `cast --calldata-decode` we will see this requires two parameters. `<SIG>` and `<CALLDATA>`

First we can match the signature by getting the function signature and matching it with the HEX manually. To do that we can use the following command:
```bash
cast sig "transferFrom(address,address,uint256)"
```

We will get the following output:
```
0x23b872dd
```
Which matches the first 4 bytes of the HEX we got from MetaMask.

### 📝 Note
There might be cases, where two functions results in same function signature. In that case we would not be able to compile that smart contract, solidity will throw an error.

--------------

Now that we have verified the function signature, we should verify the rest of the stuffs as well. We can take the whole HEX and decode it using the following command:
```bash
cast --calldata-decode "transferFrom(address,address,uint256)" 0x23b872dd000000000000000000000000ad1c737896cd841766bed18dd052d8244331e1db000000000000000000000000ad1c737896cd841766bed18dd052d8244331e1db0000000000000000000000000000000000000000000000000000000005f5e100
```

We will get the following output:
```
0xaD1C737896cd841766BED18dd052d8244331e1DB
0xaD1C737896cd841766BED18dd052d8244331e1DB
100000000 [1e8]
```
Which are indeed the arguments we were trying to pass to the function. This means that MetaMask is indeed calling the right function in the smart contract with the right arguments.

### 📝 Note
If we wanna be absolutely sure of what our transactions are actually doing, we should follow these steps:
1. Check the address of the contract (Read the function)
2. Check the function signature / selector
3. Decode calldata