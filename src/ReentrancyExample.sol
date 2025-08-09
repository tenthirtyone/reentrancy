// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title ReentrancyExample
 * @dev This contract demonstrates reentrancy attacks and how to prevent them
 *
 * Reentrancy occurs when a function makes an external call to another untrusted contract
 * before it finishes updating its own state. The external contract can then call back
 * into the original function, potentially draining funds or manipulating state.
 */
contract ReentrancyExample {
    /// @dev Mapping to track user balances
    mapping(address account => uint256 amount) public balances;

    /// @dev Simple reentrancy guard flag
    bool private _reentrancyLock = false;

    /**
     * @dev Modifier to prevent reentrancy attacks
     * Sets a lock before function execution and releases it after
     */
    modifier nonReentrant() {
        require(!_reentrancyLock, "Reentrancy detected");
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }

    /**
     * @dev VULNERABLE: Classic reentrancy attack vector
     *
     * This function is vulnerable because:
     * 1. It makes an external call to msg.sender (potentially malicious contract)
     * 2. The external call happens BEFORE updating the balance
     * 3. A malicious contract can call this function again before balance is zeroed
     *
     * Attack scenario:
     * 1. Attacker deposits 1 ETH, balance[attacker] = 1 ETH
     * 2. Attacker calls withdraw()
     * 3. Contract sends 1 ETH to attacker (external call)
     * 4. Attacker's receive() function calls withdraw() again
     * 5. balance[attacker] is still 1 ETH (not updated yet)
     * 6. Contract sends another 1 ETH to attacker
     * 7. This repeats until contract is drained
     */
    function withdraw() public nonReentrant {
        (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(success, "Failed to withdraw");
        balances[msg.sender] = 0; // State updated AFTER external call - TOO LATE!
    }

    /**
     * @dev STILL VULNERABLE: Reentrancy guard doesn't fix the core issue
     *
     * This function has the same vulnerability as withdraw() because:
     * - The external call still happens before state update
     * - The reentrancy guard only prevents the SAME function from being called again
     * - But malicious contracts can call OTHER functions or manipulate state during the call
     *
     * The nonReentrant modifier prevents direct recursion but doesn't solve
     * the fundamental issue of external calls before state updates.
     */
    function safeWithdrawByModifier() public nonReentrant {
        (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(success, "Failed to withdraw");
        balances[msg.sender] = 0; // Still vulnerable to state manipulation
    }

    /**
     * @dev SAFE: Follows checks-effects-interactions pattern
     *
     * This function is safe because:
     * 1. Check: Verify user has a balance
     * 2. Effect: Update state (zero the balance) BEFORE external call
     * 3. Interaction: Make external call after state is updated
     *
     * Even if the external call triggers reentrancy, the balance is already
     * set to 0, so subsequent calls will have no effect.
     */
    function safeWithdrawByCheck() public {
        if (balances[msg.sender] > 0) {
            uint256 amount = balances[msg.sender];
            balances[msg.sender] = 0; // Update state BEFORE external call
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Failed to withdraw");
        }
    }

    /**
     * @dev SAFE: Follows checks-effects-interactions pattern with modifier
     *
     * This function is safe because:
     * 1. Check: Verify user has a balance
     * 2. Effect: Update state (zero the balance) BEFORE external call
     * 3. Interaction: Make external call after state is updated
     */
    function safeWithdrawByCheckAndModifier() public nonReentrant {
        if (balances[msg.sender] > 0) {
            uint256 amount = balances[msg.sender];
            balances[msg.sender] = 0; // Update state BEFORE external call
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Failed to withdraw");
        }
    }

    /**
     * @dev Internal function to handle deposits
     * @param _account Address to credit the deposit to
     * @param _amount Amount to deposit
     */
    function _deposit(address _account, uint256 _amount) internal {
        balances[_account] += _amount;
    }

    /**
     * @dev Receive function to accept ETH deposits
     * Automatically credits the sender's balance
     */
    receive() external payable {
        _deposit(msg.sender, msg.value);
    }
}
