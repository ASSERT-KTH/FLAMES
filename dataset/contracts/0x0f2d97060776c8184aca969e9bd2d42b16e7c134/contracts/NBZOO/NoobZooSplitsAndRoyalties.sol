// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract NoobZooSplitsAndRoyalties is ERC2981 {
    address[] internal addresses = [
        0xDbcB5606947783cc1dEac81Dee1F332E8767B767 // Noob Project Wallet
    ];

    uint256[] internal splits = [100];

    uint96 private constant DEFAULT_ROYALTY_BASIS_POINTS = 300;

    constructor() {
        // Default royalty information to be this contract, so that no potential
        // royalty payments are missed by marketplaces that support ERC2981.
        _setDefaultRoyalty(address(this), DEFAULT_ROYALTY_BASIS_POINTS);
    }
}
