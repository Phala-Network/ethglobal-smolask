// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
    constructor(string memory currency, string memory symbol) ERC20(currency, symbol) {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    function approveFor(address owner, address spender) external {
        _approve(owner, spender, type(uint256).max);
    }
}

contract IntentAction {
    MockERC20 token0;
    MockERC20 token1;

    constructor(address[] memory users) {
        token0 = new MockERC20("Token0 Matic", "MATIC");
        token1 = new MockERC20("Token1 USDC", "USDC");
        for (uint256 i = 0; i < users.length; i++) {
            token0.mint(users[i], 10000 ether);
            token1.mint(users[i], 10000 ether);
            token0.approveFor(users[i], address(this));
            token1.approveFor(users[i], address(this));
        }
    }

    function fill(address seller, uint256 amountToSell, address buyer, uint256 amountToBuy) external {
        token0.transferFrom(seller, buyer, amountToSell);
        token1.transferFrom(buyer, seller, amountToBuy);
    }
}
