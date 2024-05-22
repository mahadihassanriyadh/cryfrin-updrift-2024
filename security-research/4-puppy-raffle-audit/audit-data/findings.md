### [M-#] Unbounded Loop in `PuppyRaffle::enterRaffle()` function, making it vulnerable to DoS attacks, resulting in high gas costs for future entrants

**Likelihood & Impact:**
- Impact: Medium
- Likelihood: Medium
- Severity: Medium

**Description:**

The `PuppyRaffle::enterRaffle()` function loops through the `PuppyRaffle::players` array to check for duplicates. However, the loop is unbounded, meaning an attacker can flood the array with entries, causing the loop to consume a large amount of gas for future entrants. Potentially the attacker could also cause the loop to consume all available gas, preventing future entrants from participating in the raffle. The gas costs for the players who joins later will be dramatically higher than the entrants who joined earlier.

**Impact:**

The gas costs for raffle entrants will greatly increase as more players enter the raffle. Discouraging later users from entering, and causing a rush at the start of a raffle to be one of the first entrants in the queue.

An attacker might make the `PuppyRaffle::players` array so big, that no one else enters, guaranteeing themselves the win.

**Proof of Concept:**

If we have 2 sets of 100 players, who enter the raffle, the gas costs will be as such:
- 1st 100 players: ~6252047 gas
- 2nd 100 players: ~18068138 gas

This is almost 3 times more expensive for the 2nd set of players.

<details>
<summary>Code</summary>

Place the following test into the `PuppyRaffle.t.sol` file:

```js
    function testCanEnterRaffleDoSAttack() public {
        vm.txGasPrice(1);

        uint256 TOTAL_ENTRY = 100;

        /// @notice For first 100 entries
        address[] memory players = new address[](TOTAL_ENTRY);
        for (uint256 i; i < TOTAL_ENTRY; i++) {
            players[i] = address(i);
        }
        uint256 gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * TOTAL_ENTRY}(players);
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas Cost of the first %s entries: %s", TOTAL_ENTRY, gasUsed);

        console.log("########################################");

        /// @notice For second 100 entries
        players = new address[](TOTAL_ENTRY);
        for (uint256 i; i < TOTAL_ENTRY; i++) {
            players[i] = address(i + TOTAL_ENTRY);
        }
        gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * TOTAL_ENTRY}(players);
        gasEnd = gasleft();
        gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas Cost of the second %s entries: %s", TOTAL_ENTRY, gasUsed);

        assertEq(puppyRaffle.players((TOTAL_ENTRY * 2) - 1), address((TOTAL_ENTRY * 2) - 1));
    }
```

</details>

**Recommended Mitigation:**

1. Consider allowing duplicates. Users can make new wallet addresses anyways, so a duplicate check doesn't prevent a user from entering multiple times, only the same address.
2. Consider using a mapping to track if an address has already entered the raffle. This will prevent the need for a loop to check for duplicates.

```diff
+    mapping(address => uint256) public addressToRaffleId;
+    uint256 public raffleId = 1;
    .
    .
    .
    function enterRaffle(address[] memory newPlayers) public payable {
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
+       // Check for duplicates only from the new players
+       for (uint256 i = 0; i < newPlayers.length; i++) {
+          require(
+               addressToRaffleId[newPlayers[i]] != raffleId,
+               "PuppyRaffle: Duplicate player"
+          );
+       }    

        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
+            addressToRaffleId[newPlayers[i]] = raffleId;            
        }

-        // Check for duplicates
-        for (uint256 i = 0; i < players.length; i++) {
-            for (uint256 j = i + 1; j < players.length; j++) {
-                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-            }
-        }
        emit RaffleEnter(newPlayers);
    }
    .
    .
    .
    function selectWinner() external {
+       raffleId += 1;
        require(block.timestamp >= raffleStartTime + raffleDuration, "PuppyRaffle: Raffle not over");
```