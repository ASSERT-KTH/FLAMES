// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IERC20.sol";

interface IsDAI is IERC20 {

	function deposit(uint256 assets, address receiver) external returns (uint256);
	// DAI to sDAI

	function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);
	// sDAI to DAI

}