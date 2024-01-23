// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

import "./ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Squiggle DAO membership NFT
/// @author Arkaydeus twitter.com/arkaydeus
/// @notice ERC721 SD membership token to be minted with SQUIG
contract SdNft is ERC721, ERC721Enumerable, ERC2981, Ownable {
    using Counters for Counters.Counter;

    enum SalePhase {
        Deployed,
        Swap,
        Paused
    }

    event Minted(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    // Public variables
    SalePhase public salePhase = SalePhase.Deployed;
    address public squiggleErc20Address;

    // Values are set at deployment but are expected to be as follows
    uint256 public mintSquigPrice = 10000000;
    uint256 public squigSupply = 1000000000000000;

    // Private variables
    Counters.Counter private _tokenIdCounter;
    string private contractURI;

    /// @notice This function is called by the owner of the contract to initiate the NFT
    /// @dev SQUIG token and current supply needed to prevent further tokens being minted
    /// @dev Note that SQUIG has decimal precision of 4, so we need to multiply by 10000
    /// @param _squiggleErc20Address SQUIG deployed address
    /// @param _contractURI base path for metadata
    /// @param _mintSquigPrice price for the swap in SQUIG
    /// @param _squigSupply current supply of SQUIG issued (to prevent additional SQUIG mint)
    constructor(
        address _squiggleErc20Address,
        string memory _contractURI,
        uint256 _mintSquigPrice,
        uint256 _squigSupply
    ) ERC721("SdNft", "SQUIGGLEDAO") {
        squiggleErc20Address = _squiggleErc20Address;
        contractURI = _contractURI;
        mintSquigPrice = _mintSquigPrice;
        squigSupply = _squigSupply;
    }

    /// Mint using SQUIG
    /// @notice mints tokens in sequence in exchange for SQUIG token
    /// @param _to address to mint to
    /// @param _tokenIn SQUIG token address
    /// @param _count how many tokens to mint
    /// @param _amountIn amount of SQUIG token to use (decimals 4)
    function squigMint(
        address _to,
        address _tokenIn,
        uint256 _count,
        uint256 _amountIn
    ) external {
        require(salePhase > SalePhase.Deployed, "Swap is not yet live");
        require(salePhase < SalePhase.Paused, "Swap is currently paused");

        require(
            (_tokenIn == squiggleErc20Address),
            "Supplied token not SQUIG."
        );

        require(
            squigSupply == IERC20(squiggleErc20Address).totalSupply(),
            "SQUIG supply has changed."
        );

        require(
            (_amountIn / _count) == mintSquigPrice,
            "Transaction value did not equal swap price."
        );

        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        for (uint256 i = 0; i < _count; i++) {
            _mint(_to);
        }
    }

    /// Mint
    /// @dev internal function called by squigMint to mint a token
    /// @param _to wallet to which token is minted
    function _mint(address _to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);

        emit Minted(msg.sender, _to, tokenId);
    }

    /// Enter Phase
    /// @dev Sets the sale state allowing pause and resume
    /// @param _salePhase the phase to set
    function enterPhase(SalePhase _salePhase) external onlyOwner {
        require(_salePhase != SalePhase.Deployed, "Cannot set as deployed");
        salePhase = _salePhase;
    }

    /// Set supply
    /// @dev Reset the amount of SQUIG that has been minted in case of legitimate mint
    /// @param _squigSupply the amount of SQUIG that has been minted
    function setSupply(uint256 _squigSupply) external onlyOwner {
        squigSupply = _squigSupply;
    }

    /// Set contract URI
    /// @dev Allows the owner to change the metadata base URI
    /// @param _contractURI the new base URI
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /// Base URI
    /// @dev returns the base URI for the metadata
    function _baseURI() internal view override returns (string memory) {
        return contractURI;
    }

    /// Set default royalty
    /// @dev Allows the owner to set the default royalty
    /// @param _receiver the address to receive the royalty
    /// @param _feeNumerator the amount of the royalty in basis points (750 = 7.5%)
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
