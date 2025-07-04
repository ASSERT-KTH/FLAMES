/*
 * @source: https://github.com/trailofbits/not-so-smart-contracts/blob/master/integer_overflow/integer_overflow_1.sol
 * @author: -
 * @vulnerable_at_lines: 14
 */

 pragma solidity ^0.4.15;

 contract Overflow {
     uint private sellerBalance=0;

     function add(uint value) returns (bool){

         sellerBalance += value; // possible overflow

         // possible auditor assert
         // assert(sellerBalance >= value);
require(sellerBalance >= value);
         return true;
     }

     function withdraw(uint value) returns (bool){
require(value <= sellerBalance);
         sellerBalance -= value;
         return true;
     }

     function getBalance() returns (uint){
         return sellerBalance;
     }

     function transfer(address to, uint value) returns (bool){
         require(value <= sellerBalance);
         sellerBalance -= value;
         to.call.value(value);
         return true;
     }

     function() payable{
         sellerBalance += msg.value;
         require(msg.value >= 100 szabo);
     }

  // function safe_add(uint value) returns (bool){
  //   require(value + sellerBalance >= sellerBalance);
  // sellerBalance += value;
  // } 
 }