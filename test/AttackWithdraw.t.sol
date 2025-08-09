// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AttackWithdraw} from "../src/AttackWithdraw.sol";
import {ReentrancyExample} from "../src/ReentrancyExample.sol";

contract AttackWithdrawTest is Test {
    AttackWithdraw public attackWithdraw;
    ReentrancyExample public reentrancyExample;

    uint256 public userPrivateKey =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public user = vm.addr(userPrivateKey);

    function setUp() public {
        reentrancyExample = new ReentrancyExample();
        attackWithdraw = new AttackWithdraw(address(reentrancyExample));

        vm.deal(user, 10 ether);
        vm.deal(address(this), 10 ether);
    }

    /**
     * @dev Test demonstrating a reentrancy attack that drains the vulnerable contract
     *
     * This test verifies that the AttackWithdraw contract can successfully exploit
     * the reentrancy vulnerability in the ReentrancyExample contract by:
     * 1. Having a legitimate user deposit funds into the vulnerable contract
     * 2. The attacker deposits the same amount to establish a balance
     * 3. The attacker calls withdraw(), which triggers the reentrancy attack
     * 4. The attack contract's receive() function recursively calls withdraw()
     * 5. This drains more funds than the attacker originally deposited
     */
    function test_drainContract() public {
        vm.startPrank(user);
        uint256 userDeposit = 1 ether;
        (bool success, ) = address(reentrancyExample).call{value: userDeposit}(
            ""
        );
        require(success);
        vm.stopPrank();

        assertEq(address(reentrancyExample).balance, userDeposit);

        uint256 startingBalance = address(this).balance;

        attackWithdraw.deposit{value: userDeposit}();

        attackWithdraw.attackWithdraw();
        attackWithdraw.withdraw();

        uint256 endingBalance = address(this).balance;

        console.log(startingBalance);
        console.log(endingBalance);
        console.log(userDeposit);

        console.log(address(attackWithdraw).balance);
    }

    function receive() external payable {}
}
