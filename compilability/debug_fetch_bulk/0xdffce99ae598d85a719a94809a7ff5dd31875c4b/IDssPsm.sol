// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IDssPsm {

	function sellGem(address usr, uint256 gemAmt) external;
	// USDC to DAI

	function buyGem(address usr, uint256 gemAmt) external;
	// DAI to USDC

}