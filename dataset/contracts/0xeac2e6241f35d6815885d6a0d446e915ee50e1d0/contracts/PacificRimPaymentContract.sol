// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract PacificRimPaymentContract is Ownable, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IERC721 NFT; 

    uint256 private ethAmount; 
    uint256 private cappedSupply; 
    uint256 private mintedSupply;
 
    uint256 private preSaleTime; 
    uint256 private preSaleDuration; 
    uint256 private preSaleMintLimit; 

    uint256 private whitelistSaleTime; 
    uint256 private whitelistSaleDuration; 
    uint256 private whitelistSaleMintLimit; 

    uint256 private publicSaleTime; 
    uint256 private publicSaleDuration; 
    
    uint256 private preSalePerTransactionMintLimit;
    uint256 private whitelistSalePerTransactionMintLimit;
    uint256 private publicSalePerTransactionMintLimit;

    address payable private withdrawAddress; // address who can withdraw eth
    address private signatureAddress;

    mapping(address => uint256) private mintBalancePreSale; // in case of presale mint and whitlist mint
    mapping(address => uint256) private mintBalanceWhitelistSale;
    mapping(bytes => bool) private signatures;

    event preSaleMint(address indexed to, uint256[] tokenId, uint256 indexed price);
    event whitelistSaleMint(address indexed to, uint256[] tokenId, uint256 indexed price);
    event publicSaleMint(address indexed to, uint256[] tokenId, uint256 indexed price);
    event preSaleTimeUpdate(uint256 indexed time);
    event preSaleDurationUpdate(uint256 indexed duration);
    event whitelistSaleTimeUpdate(uint256 indexed time);
    event whitelistSaleDurationUpdate(uint256 indexed duration);
    event publicSaleTimeUpdate(uint256 indexed time);
    event publicSaleDurationUpdate(uint256 indexed duration);
    event ETHFundsWithdrawn(uint256 indexed amount, address indexed _address);
    event withdrawAddressUpdated(address indexed newAddress);
    event NFTAddressUpdated(address indexed newAddress);
    event updateETHAmount(address indexed owner, uint256 indexed amount);
    event signatureAddressUpdated(address indexed _address);
    event airdropNFT(address[] to, uint256[] tokenId);
    event cappedSupplyUpdate(address indexed owner, uint256 indexed supply);
    event preSaleMintingLimit(address indexed owner, uint256 indexed limit);
    event whitelistSaleMintingLimit(address indexed owner, uint256 indexed limit);
    event preSalePerTransactionMintLimitUpdated(uint256 indexed _perTransactionMintLimit);
    event whitelistSalePerTransactionMintLimitUpdated(uint256 indexed _perTransactionMintLimit);
    event publicSalePerTransactionMintLimitUpdated(uint256 indexed _perTransactionMintLimit);
    

    constructor(address _NFTaddress,address payable _withdrawAddress) {
        NFT = IERC721(_NFTaddress);

        ethAmount = 0 ether;
        cappedSupply = 5000;
        mintedSupply = 0;
        preSaleMintLimit = 2;
        preSalePerTransactionMintLimit = 2;
        whitelistSaleMintLimit = 1;
        whitelistSalePerTransactionMintLimit = 1;
        publicSalePerTransactionMintLimit = 1;

        preSaleTime = 1671813900; 
        preSaleDuration = 900;

        whitelistSaleTime = 1671814801;
        whitelistSaleDuration = 3600;

        publicSaleTime = 1671818401; 
        publicSaleDuration = 157766400;

        withdrawAddress = _withdrawAddress;
        signatureAddress = 0x6e90605AB3D87FC62b50D8d5526EFdd02B6678c4;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, 0x6AB132Cf61F582535397fc7E36089DD49Fef5C59);
        _setupRole(MINTER_ROLE, 0x93BD8b204D06C4510400048781cc279Baf8480e7);
    }

    function presaleMint(uint256[] memory _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount.mul(_tokenId.length),"Dapp: Invalid value!");
        require(block.timestamp >= preSaleTime,"Dapp: Presale not started!");
        require(block.timestamp <= preSaleTime.add(preSaleDuration),"Dapp: Presale ended!");
        require(mintBalancePreSale[msg.sender].add(_tokenId.length) <= preSaleMintLimit,"Dapp: Wallet's presale mint limit exceeded!");
        require(mintedSupply.add(_tokenId.length) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");
        require( _tokenId.length <= preSalePerTransactionMintLimit,"Dapp: Token id length greater than presale per transacton mint limit!");

        for(uint index=0; index<_tokenId.length; index++){

            NFT.mint(msg.sender, _tokenId[index]);
            mintedSupply++;
            mintBalancePreSale[msg.sender]++;

        }

        signatures[_signature] = true;

        emit preSaleMint(msg.sender, _tokenId, msg.value);
    }

    function whitelistMint(uint256[] memory _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount.mul(_tokenId.length),"Dapp: Invalid value!");
        require(block.timestamp >= whitelistSaleTime,"Dapp: Whitelisted sale not started!");
        require(block.timestamp <= whitelistSaleTime.add(whitelistSaleDuration),"Dapp: Whitelisted sale ended!");
        require(mintBalanceWhitelistSale[msg.sender].add(_tokenId.length) <= whitelistSaleMintLimit,"Dapp: Wallet's whitelisted sale mint limit exceeded!");
        require(mintedSupply.add(_tokenId.length) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");
        require( _tokenId.length <= whitelistSalePerTransactionMintLimit,"Dapp: Token id length greater than whitelist sale per transacton mint limit!");

        for(uint index=0; index<_tokenId.length; index++){

            NFT.mint(msg.sender, _tokenId[index]);
            mintedSupply++;
            mintBalanceWhitelistSale[msg.sender]++;

        }
        signatures[_signature] = true;

        emit whitelistSaleMint(msg.sender, _tokenId, msg.value);
    }

    function publicMint(uint256[] memory _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount.mul(_tokenId.length),"Dapp: Invalid value!");
        require(block.timestamp >= publicSaleTime,"Dapp: Public sale not started!");
        require(block.timestamp <= publicSaleTime.add(publicSaleDuration),"Dapp: Public sale ended!");
        require(mintedSupply.add(_tokenId.length) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");
        require(_tokenId.length <= publicSalePerTransactionMintLimit,"Dapp: Token id length greater than public per transacton mint limit!");

        for(uint index=0; index<_tokenId.length; index++){

            NFT.mint(msg.sender, _tokenId[index]);
            mintedSupply++;

        }
        
        signatures[_signature] = true;

        emit publicSaleMint(msg.sender, _tokenId, msg.value);
    }

    function updatePresaleTime(uint256 _presaleTime) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_presaleTime>block.timestamp,"Dapp: Start time should be greater than current time!");
        
        preSaleTime = _presaleTime;

        emit preSaleTimeUpdate(_presaleTime);
    }

    function updatePresaleDuration(uint256 _presaleDuration) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_presaleDuration>0,"Dapp: Invalid duration value!");

        preSaleDuration = _presaleDuration;

        emit preSaleDurationUpdate(_presaleDuration);
    }

    function updateWhitelistSaleTime(uint256 _whitelistSaleTime) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_whitelistSaleTime>preSaleTime.add(preSaleDuration),"Dapp: Whitelist sale start time should be greater than presale duration!");

        whitelistSaleTime = _whitelistSaleTime;

        emit whitelistSaleTimeUpdate(_whitelistSaleTime);
    }

    function updateWhitelistSaleDuration(uint256 _whitelistSaleDuration) public {
        require(_whitelistSaleDuration>0,"Dapp: Invalid duration value!");
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");

        whitelistSaleDuration = _whitelistSaleDuration;

        emit whitelistSaleDurationUpdate(_whitelistSaleDuration);
    }

    function updatePublicSaleTime(uint256 _publicSaleTime) public {
        require(_publicSaleTime>whitelistSaleTime.add(whitelistSaleDuration),"Dapp: Public sale start time should be greater than whitelist sale duration!");
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");

        publicSaleTime = _publicSaleTime;

        emit publicSaleTimeUpdate(_publicSaleTime);
    }

    function updatePublicSaleDuration(uint256 _publicSaleDuration) public {
        require(_publicSaleDuration>0,"Dapp: Invalid duration value!");
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");

        publicSaleDuration = _publicSaleDuration;

        emit publicSaleDurationUpdate(_publicSaleDuration);
    }

    function withdrawEthFunds(uint256 _amount) public onlyOwner nonReentrant{

        require(_amount > 0,"Dapp: invalid amount.");

        withdrawAddress.transfer(_amount);
        emit ETHFundsWithdrawn(_amount, msg.sender);

    }

    function updateWithdrawAddress(address payable _withdrawAddress) public onlyOwner{
        require(_withdrawAddress != withdrawAddress,"Dapp: Invalid address.");
        require(_withdrawAddress != address(0),"Dapp: Invalid address.");

        withdrawAddress = _withdrawAddress;
        emit withdrawAddressUpdated(_withdrawAddress);

    }

    function airdrop(address[] memory to, uint256[] memory tokenId) public {
        require(hasRole(MINTER_ROLE, _msgSender()),"Dapp: Must have minter role to mint.");
        require(to.length == tokenId.length,"Dapp: Length of token id and address are not equal!");
        require(mintedSupply.add(tokenId.length) <= cappedSupply,"Dapp: Capped value rached!");

        for (uint index = 0; index < to.length; index++) {
            NFT.mint(to[index], tokenId[index]);
            mintedSupply++;
        }

        emit airdropNFT(to, tokenId);
    }

    function updateCapValue(uint256 _value) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_value > mintedSupply, "Dapp: Invalid capped value!");
        require(_value != 0, "Dapp: Capped value cannot be zero!");

        cappedSupply = _value;

        emit cappedSupplyUpdate(msg.sender, _value);
    }

    function updatePreSaleMintLimit(uint256 _limit) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_limit != 0, "Dapp: Cannot set to zero!");

        preSaleMintLimit = _limit;

        emit preSaleMintingLimit(msg.sender, _limit);
    }

    function updateWhitelistSaleMintLimit(uint256 _limit) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_limit != 0, "Dapp: Cannot set to zero!");

        whitelistSaleMintLimit = _limit;

        emit whitelistSaleMintingLimit(msg.sender, _limit);
    }

    function updateNFTAddress(address _address) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_address != address(0),"Dapp: Invalid address!");
        require(IERC721(_address) != NFT, "Dapp: Address already exist.");

        NFT = IERC721(_address);

        emit NFTAddressUpdated(_address);
    }

    function updateEthAmount(uint256 _amount) public  {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_amount != ethAmount, "Dapp: Invalid amount!");

        ethAmount = _amount;

        emit updateETHAmount(msg.sender, _amount);
    }

    function updateSignatureAddress(address _signatureAddress) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_signatureAddress != address(0),"Dapp: Invalid address!");
        require(_signatureAddress != signatureAddress,"Dapp! Old address passed again!");
        

        signatureAddress = _signatureAddress;

        emit signatureAddressUpdated(_signatureAddress);
    }

    function updatePublicSalePerTransactionMintLimit(uint256 _publicSalePerTransactionMintLimit) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_publicSalePerTransactionMintLimit>0,"Dapp: Invalid value!");
        require(_publicSalePerTransactionMintLimit!=publicSalePerTransactionMintLimit,"Dapp: Limit value is same as previous!");

        publicSalePerTransactionMintLimit = _publicSalePerTransactionMintLimit;

        emit publicSalePerTransactionMintLimitUpdated(_publicSalePerTransactionMintLimit);
    }

    function updatePreSalePerTransactionMintLimit(uint256 _preSalePerTransactionMintLimit) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_preSalePerTransactionMintLimit>0,"Dapp: Invalid value!");
        require(_preSalePerTransactionMintLimit!=preSalePerTransactionMintLimit,"Dapp: Limit value is same as previous!");
        require(_preSalePerTransactionMintLimit<=preSaleMintLimit,"Dapp: Per transaction mint limit cannot be greater than presale mint limit!");

        preSalePerTransactionMintLimit = _preSalePerTransactionMintLimit;

        emit preSalePerTransactionMintLimitUpdated(_preSalePerTransactionMintLimit);
    }

    function updateWhitelistSalePerTransactionMintLimit(uint256 _whitelistSalePerTransactionMintLimit) public {
        require(hasRole(ADMIN_ROLE, _msgSender()),"Dapp: Must have admin role to update.");
        require(_whitelistSalePerTransactionMintLimit>0,"Dapp: Invalid value!");
        require(_whitelistSalePerTransactionMintLimit!=whitelistSalePerTransactionMintLimit,"Dapp: Limit value is same as previous!");
        require(_whitelistSalePerTransactionMintLimit<=whitelistSaleMintLimit,"Dapp: Per transaction mint limit cannot be greater than whitelist sale mint limit!");

        whitelistSalePerTransactionMintLimit = _whitelistSalePerTransactionMintLimit;

        emit whitelistSalePerTransactionMintLimitUpdated(_whitelistSalePerTransactionMintLimit);
    }

    function getEthAmount() public view returns(uint256){
        return ethAmount;
    }

    function getCappedSupply() public view returns(uint256){
        return cappedSupply;
    }

    function getmintedSupply() public view returns(uint256){
        return mintedSupply;
    }

    function getPreSaleTime() public view returns(uint256){
        return preSaleTime;
    }

    function getPreSaleDuration() public view returns(uint256){
        return preSaleDuration;
    }

    function getPreSaleMintLimit() public view returns(uint256){
        return preSaleMintLimit;
    }

    function getWhitelistSaleTime() public view returns(uint256){
        return whitelistSaleTime;
    }

    function getWhitelistSaleDuration() public view returns(uint256){
        return whitelistSaleDuration;
    }

    function getWhitelistSaleMintLimit() public view returns(uint256){
        return whitelistSaleMintLimit;
    }

    function getPublicSaleTime() public view returns(uint256){
        return publicSaleTime;
    }

    function getPublicSaleDuration() public view returns(uint256){
        return publicSaleDuration;
    }

    function getWithdrawAddress() public view returns(address){
        return withdrawAddress;
    }

    function getMintBalancePreSale(address _address) public view returns(uint256){
        return mintBalancePreSale[_address];
    }
    
    function getMintBalanceWhitelistedSale(address _address) public view returns(uint256){
        return mintBalanceWhitelistSale[_address];
    }

    function getSignatureAddress() public view returns(address _signatureAddress){
        _signatureAddress = signatureAddress;
    }

    function checkSignatureValidity(bytes memory _signature) public view returns(bool){
        return signatures[_signature];
    }

    function getPublicSalePerTransactionMintLimit() public view returns(uint256){
        return publicSalePerTransactionMintLimit;
    }

    function getWhitelistSalePerTransactionMintLimit() public view returns(uint256){
        return whitelistSalePerTransactionMintLimit;
    }

    function getPreSalePerTransactionMintLimit() public view returns(uint256){
        return preSalePerTransactionMintLimit;
    }

    function getNFTAdress() public view returns(IERC721){
        return NFT;
    }

    function recover(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }
}
