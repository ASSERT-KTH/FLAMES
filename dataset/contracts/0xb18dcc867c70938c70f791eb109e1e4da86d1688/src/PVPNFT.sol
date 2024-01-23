// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "ERC721Psi/ERC721Psi.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "./Errors.sol";

contract PVPNFT is ERC721Psi, Ownable {
    event NewSale(address sale);
    event TokensRevealed();

    address sale;

    string private baseURI;
    bool private uriAlreadySet;

    modifier onlySale() {
        if (_msgSender() != sale) { revert Blocked(); }
        _;
    }

    modifier onlyOwnerOrSale() {
        if(
            (_msgSender() != owner()) && (_msgSender() != sale)
        ) {
            revert Blocked();
        }
        _;
    }

    constructor(address owner_, address sale_, string memory name_, string memory symbol_, string memory initialURI_) ERC721Psi(name_, symbol_) {
        transferOwnership(owner_);
        baseURI = initialURI_;
        sale = sale_;
    }

    function setSale(address sale_) external onlyOwner {
        if (sale == sale_) { revert AlreadySet(); }
        sale = sale_;
        emit NewSale(sale);
    }

    function reveal(string calldata uri_) external onlyOwner {
        if (uriAlreadySet) { revert AlreadySet(); }
        uriAlreadySet = true;
        emit TokensRevealed();
        baseURI = uri_;
    }

    function mint(address receiver_, uint256 amount_) external onlySale {
        _safeMint(receiver_, amount_);
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }
}
