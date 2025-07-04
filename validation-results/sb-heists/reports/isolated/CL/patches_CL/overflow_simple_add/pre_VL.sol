/*
 * @source: https://smartcontractsecurity.github.io/SWC-registry/docs/SWC-101#overflow-simple-addsol
 * @author: -
 * @vulnerable_at_lines: 14
 */

pragma solidity 0.4.25;

contract Overflow_Add {
    uint public balance = 1;

    function add(uint256 deposit) public {
require(deposit < 2**256 - 1);
        // <yes> <report> ARITHMETIC
        balance += deposit;
    }

    function add_safe(uint256 deposit) public {
require(deposit < 2**256 - 1);
require(deposit < 2**256 - 1);
        // <yes> <report> ARITHMETIC
        balance += deposit;
    }

    function add_safe(uint256 deposit) public {
require(deposit < 2**256 - 1);
        balance += deposit;
    }
}