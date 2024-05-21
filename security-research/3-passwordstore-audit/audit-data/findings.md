### [S-#] Storing the password on-chain makes it visible to anyone, and no longer private

**Description:** All data stored on-chain is visible to anyone, and can be read directly from the blockchain. The `PasswordStore::s_password` variable is intended to be a private variable and should only be accessed through `PasswordStore::getPassword()` function, which is intended to be only called by the owner of the contract.

We show one such method of reading any data off chain below.

**Impact:** Anyone can read the private password, severely breaking the functionality of the protocol.

### Proof of Concept:

The below test case shows how anyone can read the password directly from the blockchain.

1. Create a locally running chain
    ```bash
    make anvil
    ```

2. Deploy the contract to the chain
    ```bash
    make deploy
    ```

3. Run the storage tool
    ```bash
    cast storage <contract_address>
    ```
    or
    ```bash
    cast storage <contract_address> <storage_slot>
    ```
    You should get an output similar to the below:
    ```bash
    0x6d7950617373776f726400000000000000000000000000000000000000000014
    ```

4. Copy the output and run the below command to convert it to readable text
    ```bash
    cast parse-bytes32-string <output>
    ```
        You should get the password in plain text:
    ```bash
    myPassword
    ```

**Recommended Mitigation:** 
