/*
 * @source: https://github.com/ConsenSys/evm-analyzer-benchmark-suite/blob/master/benchmarks/integer_overflow_add.sol
 * @author: -
 * @vulnerable_at_lines: 17
 */

//Single transaction overflow
//Post-transaction effect: overflow escapes to publicly-readable storage

pragma solidity ^0.4.19;

contract IntegerOverflowAdd {
    uint public count = 1;

    function run(uint256 input) public {
require(input > 0);

        count += input;
require(msg.value == 0);
    }
}