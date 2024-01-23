// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ITreasury {
	function mint(address to_, uint256 amount_) external;

	function TOKEN() external view returns (address);

	function excessReserves() external view returns (uint256);
}

interface IDistributor {
	function distribute() external;

	function nextRewardAt(uint256 _rate) external view returns (uint256);

	function nextReward() external view returns (uint256);
}

interface IStaking {
	function stake(address _to, uint256 _amount) external;

	function unstake(address _to, uint256 _amount, bool _rebase) external;

	function rebase() external;

	function index() external view returns (uint256);
}

interface ITOKEN is IERC20Metadata {
	function mint(address to_, uint256 amount_) external;

	function burnFrom(address account_, uint256 amount_) external;

	function burn(uint256 amount_) external;

	function uniswapV2Pair() external view returns (address);
}

interface IsStakingProtocol is IERC20 {
	function rebase(uint256 amount_, uint epoch_) external returns (uint256);

	function circulatingSupply() external view returns (uint256);

	function gonsForBalance(uint amount) external view returns (uint);

	function balanceForGons(uint gons) external view returns (uint);

	function index() external view returns (uint);
}
