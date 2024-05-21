# [S-#] Storing the password on-chain makes it visible to anyone, and no longer private

### Description
All data stored on-chain is visible to anyone, and can be read directly from the blockchain. The `PasswordStore::s_password` variable is intended to be a private variable and should only be accessed through `PasswordStore::getPassword()` function, which is intended to be only called by the owner of the contract.

We show one such method of reading any data off chain below.

### Impact 
Anyone can read the private password, severely breaking the functionality of the protocol.

## Proof of Concept
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

### Recommended Mitigation
Due to this, the overall architecture of the contract should be rethought. One could encrypt the password off-chain, and then store the encrypted password on-chain. This would require the user to remember another password off-chain to decrypt the password. However, you'd also likely want to remove the view function as you wouldn't want the user to accidentally send a transaction with the password that decrypts your password.

# [S-#] `PasswordStore::setPassword()` function has no access control, meaning anyone can change the password

### Description
The natspec comment for the `PasswordStore::setPassword()` function states `This function allows only the owner to set a new password` but there is no access control in the function to enforce this. This means that anyone can call this function and change the password.
```javascript
    function setPassword(string memory newPassword) external {
        // @audit-bug no access control
        s_password = newPassword;
        emit SetNetPassword();
    }
```

### Impact 
Anyone can set/change the password of the contract, severely breaking the functionality of the contract.

## Proof of Concept

### Recommended Mitigation

### Three Things to Remember