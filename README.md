# Reentrancy Attack Demo

Re-entrancy is a well-known Ethereum/Web3 vulnerability. It is not inherently a flaw in the Ethereum Virtual Machine. Re-entrancy is an intentional feature that enables composability between smart contracts. Exploits occurs when developers fail to account for the fact their contract shares execution context with other contracts it calls. A called contract gains control of execution. It can make a “call-back” into the original contract before state changes complete. Without proper state management or explicit re-entrancy guards, this can trigger an unintended loop. The effect is like withdrawing $100 from an ATM and, before the machine updates your balance, immediately withdrawing the same $100 again. On Ethereum, attackers repeat this loop until the targeted contract is drained or the transaction runs out of gas.

## What's Here

- `src/ReentrancyExample.sol` - Vulnerable contract with deposit/withdraw functions
- `src/AttackWithdraw.sol` - Malicious contract that drains the vulnerable one
- Tests that show the attack working

## The Vulnerability

The `withdraw()` function sends ETH before updating the balance:

```solidity
function withdraw() public {
    (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
    require(success, "Failed to withdraw");
    balances[msg.sender] = 0; // TOO LATE!
}
```

## The Attack

1. Attacker deposits 1 ETH
2. Calls `withdraw()`
3. During the ETH transfer, attacker's `receive()` function calls `withdraw()` again
4. Repeats until contract is drained

## Run It

```bash
forge test
```

The attack test passes, showing the vulnerability works.
