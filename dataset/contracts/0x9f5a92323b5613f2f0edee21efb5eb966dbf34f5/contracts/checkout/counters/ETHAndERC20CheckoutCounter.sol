// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../checkouters/ERC20Checkouter.sol";
import "../checkouters/ETHCheckouter.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ETHAndERC20CheckoutCounter is Ownable, ERC20Checkouter, ETHCheckouter {
    using Address for address;
    using SafeMath for uint256;

    constructor() {
    }
}