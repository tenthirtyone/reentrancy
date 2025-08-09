// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ReentrancyExample} from "../src/ReentrancyExample.sol";

contract ReentrancyExampleTest is Test {
    ReentrancyExample public reentrancyExample;

    function setUp() public {
        reentrancyExample = new ReentrancyExample();
        vm.deal(address(this), 10 ether);
    }

    function test_deposit() public {
        (bool success, ) = address(reentrancyExample).call{value: 1 ether}("");
        require(success);
        assertEq(reentrancyExample.balances(address(this)), 1 ether);
    }

    function test_withdraw() public {
        (bool success, ) = address(reentrancyExample).call{value: 1 ether}("");
        require(success);
        reentrancyExample.withdraw();
        assertEq(reentrancyExample.balances(address(this)), 0);
    }

    function test_safeWithdrawByCheck() public {
        (bool success, ) = address(reentrancyExample).call{value: 1 ether}("");
        require(success);
        reentrancyExample.safeWithdrawByCheck();
        assertEq(reentrancyExample.balances(address(this)), 0);
    }

    receive() external payable {}
}
