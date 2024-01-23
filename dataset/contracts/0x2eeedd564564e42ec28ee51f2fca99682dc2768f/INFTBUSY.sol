// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTBUSY {
    enum SaleStatus {
        PAUSED,
        PRESALE,
        PUBLIC
    }

    function setPaymentAddress(address paymentAddress) external;

    function setMintPrice(uint256) external;

    function setBaseURL(string memory url) external;

    function mint(uint256 count) external payable;

    function withdraw() external;

    function mintedCount(address mintAddress) external returns (uint256);

    function airdrop(address receiver,uint256 count) external;
}