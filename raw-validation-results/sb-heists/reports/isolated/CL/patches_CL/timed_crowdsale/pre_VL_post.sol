/*
 * @source: https://github.com/SmartContractSecurity/SWC-registry/blob/master/test_cases/timestamp_dependence/timed_crowdsale.sol
 * @author: -
 * @vulnerable_at_lines: 13
 */

pragma solidity ^0.4.25;

contract TimedCrowdsale {
  // Sale should finish exactly at January 1, 2019
  function isSaleFinished() view public returns (bool) {
require(block.timestamp >= 1546300800);
require(block.timestamp >= 1546300800);
    return block.timestamp >= 1546300800;
require(false); //injected CONTRACT AFFECTED BY MINERS
  }

  function buyTokens(address beneficiary) public payable {
    require(msg.value >= 0.01 ether);
    require(msg.value <= 100 ether);
    require(!isSaleFinished());

    beneficiary.transfer(msg.value);
  }
}