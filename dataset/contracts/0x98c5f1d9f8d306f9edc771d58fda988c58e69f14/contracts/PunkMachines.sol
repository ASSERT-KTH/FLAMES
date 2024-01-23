// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&??#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5!!?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7!!!G@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#!!!!J@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!!!!!5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&J!!!!!!G@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!!!!!!!?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P!!!!!!!!5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5!!!!!!!!!?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B7!!!!!!!!!!!YBBBBB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GY7!!!!!!!!!!!!!!!!!!7JPB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGPJ?7!!!!!!!!!!!!!!!!!!!!!!!!!!7JGB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ77!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?JG&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@P?!!!!!!!!!!!!!!!!!!!77!!!!!!!!!!!!!!!!!!!!!!!7G@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@&BP?!!!!!!!!!!!!!!!!!!!!!GG7!!!!!!!!7!!!!!!!!!!!!!!!JG#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@G?!!!!!!!!!!!!77YP!!!!!!!Y@@B!!!!!!!!PBY?7!!!!!!!!!!!!!7YB@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&5!!!!!!!!!!!7?P#&@5!!!!!!?&@@@J!!!!!!!J@@@#BP?7!!!!!!!!!!!!P@@@@@@@@@@@@&BP5YJY&
@@@@@@@@@@@@@@@@@@B?!!!!!!!!!!?P#@@@@P!!!!!!!G@@@@&?!!!!!!!P@@@@@@#P7!!!!!!!!!!!?5GGBBGP5J??7!!!!!?&
@@@@@@@@@@@@@@@@&Y!!!!!!!!!75B@@@@@@#7!!!!!!!#@@@@@#?!!!!!!!Y@@@@@@@&G?!!!!!!!!!!!!!!!!!!!!!!7JPB#@@
@@@@@@@@@@@@@@@@Y!!!!!!!!!Y#@@@@@@@#7!!!!!!!Y@@@@@@@#7!!!!!!!Y&@@@@@@@&Y!!!!!!!!!!!!!!!!!!!JG&@@@@@@
@@@@@@@@@@@@@@#J!!!!!!!!?B@@@@@@@@&?!!!!!!!?B@@@@@@@@G7!!!!!!!P@@&#B5J?7!!!!!!!!!!!!!!!!7YB@@@@@@@@@
@@@@@@@@@@@@@#7!!!!!!!!J#@@@@@@@@@5!!!!!!!?@@@@@@@@@@@B7!!!!!!?J?7!!!!!!!!!!!!!!!!!!!7YG&@@@@@@@@@@@
@@@@@@@@@@@@@Y!!!!!!!!7&@@@@@@@@@#?!!!!!!!P@@@@@@@@@@@@J!!!!!!!!!!!!!!!!!!!7?!!!!!!!!P@@@@@@@@@@@@@@
@@@@@@@@@@@@Y!!!!!!!!!B@@@@@@@@@&?!!!!!!!J@@@@@@&#PYJ??!!!!!!!!!!!!!!!77?JP#@P!!!!!!!5@@@@@@@@@@@@@@
@@@@@@@@@@@G!!!!!!!!!Y@@@@@@@@@@G!!!!!!!?BBG5YJ?77!!!!!!!!!!!!!!!!?Y5G#&@@@@@#!!!!!!!?@@@@@@@@@@@@@@
@@@@@@@@@@#?!!!!!!!!7&@@@@@@@@@@J!!!!!!!77!!!!!!!!!!!!!!!!!!!!!!!!?B@@@@@@@@@P!!!!!!!?@@@@@@@@@@@@@@
@@@@@@@@@@5!!!!!!!!!5@@@@@&GYJJ?!!!!!!!!!!!!!!!!!!!!!7?JYY?!!!!!!!!7&@@@@@@@@Y!!!!!!!J@@@@@@@@@@@@@@
@@@@@@@@@@#!!!!!!!!!G@BP5J7!!!!!!!!!!!!!!!!!7777YGBB#&@@@@@G7!!!!!!!5@@@@@@@@J!!!!!!!Y@@@@@@@@@@@@@@
@@@@@@@@@@@J!!!!!!!!J?!!!!!!!!!!!!!!!!!7JPB###&&@@@@@@@@@@@@P!!!!!!!!P@@@@@@@?!!!!!!!J@@@@@@@@@@@@@@
@@@@@@@@@@@B!!!!!!!!!!!!!!!!!!!!!!!!!!5#@@@@@@@@@@@@@@@@@@@@B!!!!!!!!!B@@@@@G!!!!!!!!B@@@@@@@@@@@@@@
@@@@@@@@@@@5!!!!!!!!!!!!!!!!!!!!!!!!7G@@@@@@@@@@@@@@@@@@@@@@@5!!!!!!!!G@@@@&7!!!!!!!!G@@@@@@@@@@@@@@
@@@@@@@@#5?!!!!!!!!!!!!7?J?!!!!!!!!7G@@@@@@@@@@@@@@@@@@@@@@@@&?!!!!!!!J&@@&J!!!!!!!!7#@@@@@@@@@@@@@@
@@@@@#5?!!!!!!!!!!!!!7G&@#7!!!!!!!7B@@@@@@@@@@@@@@@@@@@@@@@@@@B7!!!!!!!5@@Y!!!!!!!!?B@@@@@@@@@@@@@@@
@&BY?7!!!!!77!!!!!!!!7&@@Y!!!!!!!!G@@@@@@@@@@@@@@@@@@@@@@@@@@@@G7!!!!!!7?5?!!!!!!!7G@@@@@@@@@@@@@@@@
B!!!!!77?JYB&Y!!!!!!!!?PB!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!!!!!!!!!!!!!!!!!?@@@@@@@@@@@@@@@@@
&PPPPB#&@@@@@@5!!!!!!!!!7!!!!!!!!G@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J!!!!!!!!!!!!!!!J#@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@BJ!!!!!!!!!!!!!!!7&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&J!!!!!!!!!!!!J#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@BY!!!!!!!!!!!!!7YGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@BP?!!!!!!!!!!!P@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@B57!!!!!!!!!!!!!!7?PGP#&@@@@@@@@@@@@@@@&##G5?!!!!!!!!!!!!!!G@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&Y!!!!!!!!!!!!!!!!!!77?555PGB##GGPPYJ77!!!!!!!!!!!!!!!!!!5@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@P!!!!!?Y?7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?J!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@Y!!!!?#@@B5J!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?YPB&@PY7!!!!7#@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@#!!!!!B@@@@@@#GPP5J??7!!!!!!!!!!!!!!!!!7J5G#@@@@@@@@B7!!!!?@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@J!!!7G@@@@@@@@@@@@@@@&#BBBBGPPPPPGGBBBB&@@@@@@@@@@@@@Y!!!!!P@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&7!!!Y@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y!!!7&@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@PJJ5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJJJ&@@@@@@@@@@@@@@@@@@
*/
contract PunkMachines is ERC721A, Ownable {
    using SafeMath for uint256;

    bytes32 public merkleRoot = 0x801a612b25769b33e25cfdf223e744315abb04662595f6252423b29ff781a9dd;

    bool public revealed = false;
    bool public mintActive = false;

    string public baseURI = '';
    string public nonRevealURI= 'https://punk-machines.nyc3.digitaloceanspaces.com/reveal/json/';

    uint256 public price = 0.0066 ether;
    uint256 public whitelistPrice = 0.0044 ether;
    uint256 public mintLimit = 10;
    uint256 public maxSupply = 888;

    constructor() ERC721A("Punk Machines", "PUM") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            return bytes(nonRevealURI).length != 0 ? string(abi.encodePacked(nonRevealURI, _toString(tokenId), '.json')) : '';
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
    }

    function mint(uint256 quantity) external payable {
        require(mintActive, "The mint is not live.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        require(_numberMinted(msg.sender).add(quantity) <= mintLimit, "The requested mint quantity exceeds the mint limit.");
        require(price.mul(quantity) <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        require(mintActive, "The mint is not live.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof.");
        require(totalSupply().add(quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        require(_numberMinted(msg.sender).add(quantity) <= mintLimit, "The requested mint quantity exceeds the mint limit.");
        require(whitelistPrice.mul(quantity) <= msg.value, "Not enough ETH for mint transaction.");

        _mint(msg.sender, quantity);
    }

    function airdrop(address[] memory _addresses) external onlyOwner {
        require(totalSupply().add(_addresses.length) <= maxSupply, "The requested mint quantity exceeds the supply.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    function mintTo(uint256 _quantity, address _receiver) external onlyOwner {
        require(totalSupply().add(_quantity) <= maxSupply, "The requested mint quantity exceeds the supply.");
        _mint(_receiver, _quantity);
    }

    function fundsWithdraw() external onlyOwner {
        uint256 funds = address(this).balance;
        require(funds > 0, "Insufficient balance.");

        (bool status,) = payable(msg.sender).call{value : funds}("");
        require(status, "Transfer failed.");
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNonRevealUri(string memory _nonRevealURI) external onlyOwner {
        nonRevealURI = _nonRevealURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
}
