
// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRevealed721NFT is IERC721 {
    function revealMint(address wallet, uint256 tokenId) external;
}