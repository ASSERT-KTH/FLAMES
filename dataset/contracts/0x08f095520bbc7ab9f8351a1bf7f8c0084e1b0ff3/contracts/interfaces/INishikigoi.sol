// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface INishikigoi {

    // functions of target contract

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory);

    function buy(uint256 tokenId) external payable;

    function buyBundle(uint256[] memory tokenIdList) external payable;

    function updateSaleStatus(bool _isOnSale) external;

    function updateBaseURI(string calldata newBaseURI) external;

    function mintForPromotion(address to, uint256 amount) external;

    function withdrawETH() external;

    function transferOwnership(address newOwner) external;

    // functions for ERC721

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}