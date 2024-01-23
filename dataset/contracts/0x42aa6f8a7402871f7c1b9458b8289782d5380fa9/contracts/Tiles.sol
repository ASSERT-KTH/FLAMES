//SPDX-License-Identifier: MIT

/*
────────────────────────────────────────────────────────────────────────
─██████████████─██████████─██████─────────██████████████─██████████████─
─██░░░░░░░░░░██─██░░░░░░██─██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██─
─██████░░██████─████░░████─██░░██─────────██░░██████████─██░░██████████─
─────██░░██───────██░░██───██░░██─────────██░░██─────────██░░██─────────
─────██░░██───────██░░██───██░░██─────────██░░██████████─██░░██████████─
─────██░░██───────██░░██───██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██─
─────██░░██───────██░░██───██░░██─────────██░░██████████─██████████░░██─
─────██░░██───────██░░██───██░░██─────────██░░██─────────────────██░░██─
─────██░░██─────████░░████─██░░██████████─██░░██████████─██████████░░██─
─────██░░██─────██░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─
─────██████─────██████████─██████████████─██████████████─██████████████─
────────────────────────────────────────────────────────────────────────
*/

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "opensea-operator-filterer/DefaultOperatorFilterer.sol";

contract Tiles is DefaultOperatorFilterer, Ownable, ERC721Enumerable {
    constructor() ERC721("Tiles", "TILES") {}

    uint256 public maxSupply = 999;
    uint256 minted;
    string public baseURI;
    string public baseExtension = ".json";
    mapping(address => uint256) userMint;
    bool public paused = true;

    function claim(uint256 _tokenID) public payable {
    require(msg.value >= 0.01 ether, "Tiles are 0.01 each!");
    require(minted < maxSupply, "Tiles are sold out!");
    require(_tokenID < maxSupply, "Please pick a Tile between zero and 999!");
    require(!_exists(_tokenID), "This Tile already exists!");
    require(!paused, "It isn't time... yet!");

    userMint[msg.sender] += 1;
    minted++;
    _safeMint(msg.sender, _tokenID);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = string(abi.encodePacked(_newBaseURI));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _exists(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }
}