// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IMadMemberPass.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MadMemberPassSeller is AccessControl, Ownable, Pausable {
    IMadMemberPass public madMemberPass;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    address public withdrawAddress;

    // SaleInfo
    uint256 public maxSupply;
    uint256 public mintCost;
    bytes32 merkleRoot;

    // Modifier
    modifier enoughEth(uint256 _amount) {
        require(mintCost > 0 && msg.value >= _amount * mintCost, 'Not Enough Eth');
        _;
    }
    modifier withinMaxSupply(uint256 _amount) {
        require(madMemberPass.getTotalSupply() + _amount <= maxSupply, 'Over Max Supply');
        _;
    }
    modifier validProof(address _address, bytes32[] calldata _merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(_address));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }

    // Constructor
    constructor() {
        _grantRole(ADMIN, msg.sender);
        withdrawAddress = msg.sender;
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // Mint
    function mint(uint256 _amount, bytes32[] calldata _merkleProof) external payable
        whenNotPaused
        withinMaxSupply(_amount)
        enoughEth(_amount)
        validProof(msg.sender, _merkleProof)
    {
        madMemberPass.mint(msg.sender, _amount);
    }

    // AirDrop
    function airdrop(address[] calldata _addresses, uint256[] calldata _amounts) payable external onlyRole(ADMIN) {
        require(_addresses.length == _amounts.length, 'Invalid Arguments');
        uint256 supply = madMemberPass.getTotalSupply();
        for (uint256 i = 0; i < _addresses.length; i++) {
            uint256 _amount = _amounts[i];
            require(supply + _amount <= maxSupply, 'Over Max Supply');
            if (supply + _amount <= maxSupply) {
                madMemberPass.mint(_addresses[i], _amount);
                supply = supply + _amount;
            }
        }
    }

    // Getter
    function totalSupply() external view returns (uint256) {
        return madMemberPass.getTotalSupply();
    }

    // Setter
    function setMadMemberPass(address _address) external onlyRole(ADMIN) {
        madMemberPass = IMadMemberPass(_address);
    }
    function setWithdrawAddress(address _value) external onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setSalesInfo( uint256 _maxSupply, uint256 _mintCost, bytes32 _merkleRoot) external onlyRole(ADMIN) {
        maxSupply = _maxSupply;
        mintCost = _mintCost;
        merkleRoot = _merkleRoot;
    }
    function setMaxSupply(uint256 _value) external onlyRole(ADMIN) {
        maxSupply = _value;
    }
    function setMintCost(uint256 _value) external onlyRole(ADMIN) {
        mintCost = _value;
    }
    function setMerkleRoot(bytes32 _value) external onlyRole(ADMIN) {
        merkleRoot = _value;
    }

    // withdraw
    function withdraw() external payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }
}