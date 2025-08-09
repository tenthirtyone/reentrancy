# Task 1 Perverse Economic Incentives

The harder part of protocol design, beyond the software, is understanding how economic scaling impacts the behavior of your protocol. Its often overlooked that public protocols are public bug bounties whose rewards scale as the protocol accrues value. Probably the most well known example of this is Bitcoin 51% attack. Bitcoin relies on aligned economic incentive among the network actors to maintain the network/blockchain. A key safety feature is that mining equipment is an arms race. It requires constant maintenance and reinvestment. If hash rate suddenly became very cheap, or a minority of actors could collude to cheaply subvert the network, the protocol failure becomes an incentive to the dishonest actor.

A recent example of a failure to scale economic incentives is the UMA Oracle network that powers Polymarket. Polymarket is a prediction market. It relies on the UMA oracles network to attest to off chain data. A baseball game between the Astros and Dodgers ended, 18 - 1. A $200,000 bet created enough perverse economic incentive for a whale to purchase enough UMA tokens to attest the Dodgers won and outvote the other UMA token holders in the dispute resolution process. Essentially, the whale knew they could spend up to the $200,000 bet and still make a profit.

This vector occurs frequently, and often in unexpected places. Transaction bundling, is another great example. Flashblocks and Jito are essentially centralized services. Base Flashblocks are run on a single instance controlled by Coinbase. Sure, these are physical entities who can be held accountable. But it is essentially just smoke and mirrors around centralization. If Flashblocks or Jito wanted to, they could control transaction ordering within their bundling system. For example, if they were to see the equivalent of a "winning lottery ticket" being redeemed on chain, they could insert their own redemption tx in front of it. The same is true for centralized order books in a CEX.

As we continue to move responsibility away from the miners, we continue to create new actors with responsibilities on the network that we don't fully understand. Furthermore, we are unable to see how all of these players interact until we reach some non-trivial level of funding and the incentives shift enough to make the zero day exploits tremendously valuable.

# Task 2 Reentrancy Attack Demo

Re-entrancy is a well-known Ethereum/Web3 vulnerability. It is not inherently a flaw in the Ethereum Virtual Machine. Re-entrancy is an intentional feature that enables composability between smart contracts. Exploits occur when developers fail to account for the fact their contract shares execution context with other contracts it calls. A called contract gains control of execution. It can make a “call-back” into the original contract before state changes complete. Without proper state management or explicit re-entrancy guards, this can trigger an unintended loop. The effect is like withdrawing $100 from an ATM and, before the machine updates your balance, immediately withdrawing the same $100 again. On Ethereum, attackers repeat this loop until the targeted contract is drained or the transaction runs out of gas.

This exploit was made famous in the Slockit DAO hack of 2016. An attacker exploited a re-entrancy flaw in the `split` function to recursively withdraw funds. They siphoned approximately 3.6M ETH. The attack almost destroyed Ethereum and led to the creation of a one-time hard fork roll back. Dissenters to the chain roll back continued on the Ethereum Classic chain.

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

## Mitigations

The `ReentrancyExample.sol` contract demonstrates several mitigation strategies:

### 1. Checks-Effects-Interactions Pattern

```solidity
function safeWithdrawByCheck() public {
    if (balances[msg.sender] > 0) {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0; // Update state BEFORE external call
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw");
    }
}
```

### 2. Reentrancy Guard (Partial Protection)

```solidity
modifier nonReentrant() {
    require(!_reentrancyLock, "Reentrancy detected");
    _reentrancyLock = true;
    _;
    _reentrancyLock = false;
}

function safeWithdrawByModifier() public nonReentrant {
    // Still vulnerable - external call before state update
}
```

### 3. Combined Approach (Recommended)

```solidity
function safeWithdrawByCheckAndModifier() public nonReentrant {
    if (balances[msg.sender] > 0) {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0; // State update first
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw");
    }
}
```

**Key takeaway**: Reentrancy guards alone are insufficient. Always update state before external calls.
