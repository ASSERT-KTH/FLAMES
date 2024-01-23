// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./MoonSaleBase.sol";

/**
 * @title MoonSaleCustom
 * @notice This is a  whitelisted sale contract. Every whitelisted address
 * can buy the same amount of tokens on a FCFS basis.
 */
contract MoonSaleCustom is MoonSaleBase {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public allocations;

    constructor(
        address _saleToken,
        uint256 _price,
        address _defaultPaymentToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _claimTime,
        uint256 _maxTotal,
        address _treasury,
        uint256[4] memory _vestingData
    )
        MoonSaleBase(
            _saleToken,
            _price,
            _defaultPaymentToken,
            _startTime,
            _endTime,
            _claimTime,
            _maxTotal,
            _treasury,
            _vestingData
        )
    {}

    function getMaxAllocation(
        address _address
    ) public view override returns (uint256) {
        return allocations[_address];
    }

    function setAllocations(
        address[] memory _addresses,
        uint256[] memory _allocations
    ) external onlyOwner {
        require(_addresses.length == _allocations.length, "length mismatch");

        for (uint256 i = 0; i < _addresses.length; i++) {
            allocations[_addresses[i]] = _allocations[i];
        }
    }
}
// solhint-enable not-rely-on-time
