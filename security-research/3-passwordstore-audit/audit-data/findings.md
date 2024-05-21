# [H-1] Storing the password on-chain makes it visible to anyone, and no longer private

### Likelihood & Impact
- Impact: High
- Likelihood: High
- Severity: High / Critical

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

# [H-2] `PasswordStore::setPassword()` function has no access control, meaning anyone can change the password

### Likelihood & Impact
- Impact: High
- Likelihood: High
- Severity: High / Critical

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
Add the following to the `PasswordStore.t.sol` file:
<details>
<summary>Code</summary>

```javascript
    function test_anyone_can_set_password(address _randomAddress) public {
        vm.assume(_randomAddress != owner);
        vm.startPrank(_randomAddress);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);

        vm.startPrank(owner);
        string memory actualPassword = passwordStore.getPassword();

        assertEq(actualPassword, expectedPassword);
    }
```

</details>

### Recommended Mitigation
Add an access control modifier to the `setPassword()` function to ensure only the owner can change the password.
```javascript
    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert PasswordStore__NotOwner();
        }
        _;
    }
```

# [I-1] The `PasswordStore::getPassword()` netspec indicates a parameter that doesn't exist, causing the netspec to be incorrect

### Likelihood & Impact
- Impact: None
- Likelihood: Low
- Severity: Informational / Gas / Non-critical

### Description
```javascript
    /**
     * @notice This allows only the owner to retrieve the password.
     * @audit-doc there is no parameter needed for this function, so the below comment is incorrect and should be removed
     * @param newPassword The new password to set.
     */
    function getPassword() external view returns (string memory) {
```

### Impact 
The natspec comment is incorrect and could cause confusion for developers reading the code.

### Recommended Mitigation
Remove the incorrect natspec comment.
```diff
-   * @param newPassword The new password to set.
+
```