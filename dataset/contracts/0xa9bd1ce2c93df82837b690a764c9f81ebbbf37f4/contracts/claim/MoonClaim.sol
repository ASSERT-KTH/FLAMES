// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "./ClaimConfigurable.sol";

contract MoonClaim is ClaimConfigurable {
    // public constant address
    address public constant APP = 0xC5d27F27F08D1FD1E3EbBAa50b3442e6c0D50439;

    constructor(
        uint256 _claimTime,
        uint256[4] memory _vestingData
    ) ClaimConfigurable(_claimTime, APP, _vestingData) {}
}
