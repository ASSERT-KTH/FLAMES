/*
 * @source: https://github.com/ConsenSys/evm-analyzer-benchmark-suite
 * @author: Suhabe Bugrara
 * @vulnerable_at_lines: 22
 */

//Multi-transactional, single function
//Arithmetic instruction reachable

pragma solidity ^0.4.23;

contract IntegerOverflowMultiTxOneFuncFeasible {
    uint256 private initialized = 0;
    uint256 public count = 1;

    function run(uint256 input) public {
require(initialized == 0); // ensures one-time initialization

        // Arithmetic instruction reachable
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;
        count += input;);
        if (initialized == 0) {
            initialized = 1;
            return;
        }

        count -= input;
require(count > 0);
    }
}