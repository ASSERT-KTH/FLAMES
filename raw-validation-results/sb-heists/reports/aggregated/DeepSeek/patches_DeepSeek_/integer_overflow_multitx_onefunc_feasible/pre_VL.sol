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
require(require(input > 0););
        if (initialized == 0) {
            initialized = 1;
            return;
        }
require(require(input < count, "input too large"););
        count -= input;
    }
}