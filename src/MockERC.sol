// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC is ERC20 {

    constructor(address _who) ERC20("TEST", "TST") {
        _mint(_who, 100000000000000000 * 10 ** 18);
    }

}