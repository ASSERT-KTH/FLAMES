pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Renegade5 is ERC721A, Ownable  {
  uint256 public cost = 0.004 ether;
  uint256 public maxSupply = 2222;
  uint256 public maxPerWallet = 3;

  error SaleNotActive();
  error MaxSupplyReached();
  error MaxPerWalletReached();
  error MaxPerTxReached();
  error NotEnoughETH();
  error NoContractMint();

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) payable {
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }
  
  function setSupply(uint256 _newSupply) external onlyOwner {
    maxSupply = _newSupply;
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  bool public sale = false;
  string public baseURI;

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function toggleSale(bool _toggle) external onlyOwner {
    sale = _toggle;
  }

  function mintTo(uint256 _amount, address _to) external onlyOwner {
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    _mint(_to, _amount);
  }

  function mintRenegade(uint256 _amount) external payable {
    if (tx.origin != msg.sender) revert NoContractMint();
    if (!sale) revert SaleNotActive();
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    if (_numberMinted(msg.sender) + _amount > maxPerWallet) revert MaxPerWalletReached();
    if (msg.value < cost * _amount) revert NotEnoughETH();

    _mint(msg.sender, _amount);
  }

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}