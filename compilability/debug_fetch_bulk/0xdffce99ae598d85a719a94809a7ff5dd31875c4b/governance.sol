// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Governance {

	address public owner;
	uint256 private fee = 5;
	mapping(address => bool) private whitelist;
	mapping(address => uint256) private specialFee;

	constructor() {
		owner = msg.sender;
	}

	modifier ownerOnly {
		require(msg.sender == owner, "Governance: Access denied");
		_;
	}

	modifier whitelistedOnly {
		require(isWhitelisted(msg.sender), "Governance: Access denied");
		_;
	}

	function isWhitelisted(address user) public view returns(bool) {
		if (user == owner) {
			return true;
		} else {
			return whitelist[user];
		}
	}

	function getFee(address user) public view returns(uint256) {
		if (user == owner) {
			return 0;
		} else if (specialFee[user] == 0) {
			return fee;
		} else {
			return specialFee[user];
		}
	}

	function transferOwnership(address newOwner) public ownerOnly {
		owner = newOwner;
	}

	function addToWhitelist(address user) public ownerOnly {
		whitelist[user] = true;
	}

	function removeFromWhitelist(address user) public ownerOnly {
		whitelist[user] = false;
	}

	function setFee(uint256 newFee) public ownerOnly {
		fee = newFee;
	}

	function setSpecialFee(address user, uint256 newSpecialFee) public ownerOnly {
		specialFee[user] = newSpecialFee;
	}

	function rescueToken(address token) public ownerOnly {
		uint256 amount = IERC20(token).balanceOf(address(this));
		require(amount > 0, "Governance: Nothing to collect");
		IERC20(token).transfer(owner, amount);
	}

}