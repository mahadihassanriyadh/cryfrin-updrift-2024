We are trying to send a transaction to the blockchain using MetaMask. A window pops up asking us to confirm the transaction. We go to the HEX tab and at the end we will see something like this:
```
0x23b872dd000000000000000000000000ad1c737896cd841766bed18dd052d8244331e1db000000000000000000000000ad1c737896cd841766bed18dd052d8244331e1db00000000000000000000000000000000000000000000d3c21bcecceda1000000
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