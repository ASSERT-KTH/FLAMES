// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./IERC2981.sol";
import "./ReferralCode.sol";
import "./FeatureKeys.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BirdFeederNFTVIP is
    Ownable,
    ERC721,
    FeatureKeys,
    ReentrancyGuard,
    IERC2981,
    Pausable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    address proxyRegistryAddress;
    address public treasury;
    uint256 public creatorRoyalty = 2;
    uint256 public discountRate = 10;
    uint256 public referralRewardPercentage = 50;
    uint256 public basicReferralRewardPercentage = 25;
    uint256 public minimumMintPrice = 50 ether;
    uint256 public lockDuration = 1 days;
    uint256 public maxMintable = 999;
    string private _contractURIMeta;
    string private baseURI = "https://";
    bool public isVIP = true;
    ReferralCode private referralContract;

    mapping(address => uint256) public discounts;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public unlockTimestamps;
    mapping(uint256 => bool) public mintedTokens;
    mapping(uint256 => string) private tokenIdToCID;
    mapping(uint256 => uint256) public tokenSupply;

    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );
    event ReferralCodeGenerated(
        address indexed user,
        uint256 indexed tokenId,
        string referralCode
    );
    event DiscountApplied(
        address indexed user,
        uint256 indexed tokenId,
        uint256 discountAmount
    );

    event ReferralRewardSent(
        address indexed user,
        address indexed referrer,
        uint256 amount
    );

    event NFTLocked(uint256 indexed tokenId, uint256 unlockTimestamp);
    event NFTUnlocked(uint256 indexed tokenId);

    event ReferralRewardPaid(
        address indexed referrer,
        uint256 indexed tokenId,
        uint256 referralReward
    );

    modifier creatorOnly(uint256 _id) {
        require(
            creators[_id] == msg.sender,
            "ERC721Tradable#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    constructor(
        address _treasury,
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        address _referralContractAddress,
        bool _isVIP
    ) ERC721(_name, _symbol) {
        isVIP = _isVIP;
        treasury = _treasury;
        proxyRegistryAddress = _proxyRegistryAddress;
        referralContract = ReferralCode(_referralContractAddress);
        _contractURIMeta = '{"name": "BirdFeeder NFTs", "description": "BirdFeeder NFTs Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.","image": "http://167.71.176.114:8080/ipfs/Qmcc8NEqGVCzzYobfriiHoW1qoMLY4mFxcdZ7Z9LssVozb","external_link": "www.birdfeeder.xyz"}';
    }

    // Set Referral Code Contract
    function setReferralContract(address _referralContract) external onlyOwner {
        referralContract = ReferralCode(_referralContract);
    }

    function _setBaseURI(string memory _uri) internal virtual {
        baseURI = _uri;
    }

    function uri(uint256 _id) public view returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        string memory data = tokenIdToCID[_id];
        return
            string(
                abi.encodePacked(
                    "https://",
                    data,
                    ".ipfs.dweb.link/",
                    _id.toString(),
                    ".json"
                )
            );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory data = tokenIdToCID[tokenId];

        // If there is no base URI, return the empty string
        if (bytes(baseURI).length == 0) {
            return "";
        }
        // If the token's data is not set, return the default tokenURI
        if (bytes(data).length == 0) {
            return
                string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }
        // If both are set, concatenate the baseURI and data
        return
            string(
                abi.encodePacked(
                    "https://",
                    data,
                    ".ipfs.dweb.link/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function _setTokenCID(
        uint256 tokenId,
        string memory _cid
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        tokenIdToCID[tokenId] = _cid;
    }

    function _exists(uint256 tokenId) internal view override returns (bool) {
        return mintedTokens[tokenId];
    }

    function _lazyMintExists(uint256 tokenId) internal view returns (bool) {
        for (uint256 i = 0; i < lazyMintCounter; i++) {
            if (lazyMints[i].tokenId == tokenId) {
                return true;
            }
        }
        return false;
    }

    // function to return the total supply of the all tokens
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function totalRemainingSupply() public view returns (uint256) {
        return maxMintable - totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balanceOf(account);
    }

    function totalMinted() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function getRemainingMintable() public view returns (uint256) {
        return maxMintable - getMintedTokensCount();
    }

    function getTokensOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 totalTokens = totalSupply();
        uint256[] memory result = new uint256[](totalTokens);
        uint256 resultIndex = 0;

        uint256 tokenId;

        for (tokenId = 1; tokenId <= totalTokens; tokenId++) {
            if (creators[tokenId] == _owner) {
                // Check if the token belongs to the owner
                result[resultIndex] = tokenId;
                resultIndex++;
            }
        }

        uint256[] memory finalResult = new uint256[](resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            finalResult[i] = result[i];
        }

        return finalResult;
    }

    function getMintedTokens() public view returns (uint256[] memory) {
        uint256 _currentTokenId = _tokenIds.current();
        uint256[] memory mintedTokensArray = new uint256[](_currentTokenId);
        uint256 counter = 0;

        for (uint256 i = 1; i <= _currentTokenId; i++) {
            if (mintedTokens[i]) {
                mintedTokensArray[counter] = i;
                counter++;
            }
        }

        // Resize the array to exclude empty elements
        uint256[] memory resizedArray = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            resizedArray[i] = mintedTokensArray[i];
        }

        return resizedArray;
    }

    function getLazyMintTokenURI(
        uint256 tokenId
    ) public view returns (string memory) {
        require(
            _lazyMintExists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        LazyMint storage lazyM;
        string memory data;

        // loop through lazyMints to find the tokenId
        for (uint256 i = 0; i < lazyMintCounter; i++) {
            if (lazyMints[i].tokenId == tokenId) {
                lazyM = lazyMints[i];
                data = lazyM.data;
                break;
            }
        }

        if (bytes(baseURI).length == 0) {
            return "";
        }
        if (bytes(data).length == 0) {
            return
                string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }
        return
            string(
                abi.encodePacked(
                    "https://",
                    data,
                    ".ipfs.dweb.link/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function setTokenData(
        uint256 tokenId,
        string memory data
    ) external onlyOwner {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        tokenIdToCID[tokenId] = data;
    }

    function setLazyMintTokenData(
        uint256 tokenId,
        string memory data
    ) external onlyOwner {
        require(
            _lazyMintExists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );

        // loop through lazyMints to find the tokenId
        for (uint256 i = 0; i < lazyMintCounter; i++) {
            if (lazyMints[i].tokenId == tokenId) {
                lazyMints[i].data = data;
                break;
            }
        }
    }

    function getMintedTokensCount() public view returns (uint256) {
        uint256[] memory mintedTokensArray = getMintedTokens();
        return mintedTokensArray.length;
    }

    function lazyBatchMint(
        string[] memory data
    ) external payable whenNotPaused returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            tokenIds[i] = tokenId;

            lazyMints[lazyMintCounter] = LazyMint({
                tokenId: tokenId,
                amount: 1,
                minter: msg.sender,
                executed: false,
                data: data[i],
                referralCode: ""
            });

            lazyMintCounter++;
        }

        return tokenIds;
    }

    function setMaxMintable(uint256 newMaxMintable) external onlyOwner {
        maxMintable = newMaxMintable;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        minimumMintPrice = newMintPrice;
    }

    function setLockDuration(uint256 newLockDuration) external onlyOwner {
        lockDuration = newLockDuration;
    }

    function _lockNFT(uint256 tokenId) internal {
        uint256 unlockTimestamp = block.timestamp + lockDuration;
        unlockTimestamps[tokenId] = unlockTimestamp;
        emit NFTLocked(tokenId, unlockTimestamp);
    }

    function _unlockNFT(uint256 tokenId) internal {
        unlockTimestamps[tokenId] = 0;
        emit NFTUnlocked(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override whenNotPaused {
        // Ensure the NFT is unlocked before transferring
        require(
            block.timestamp >= unlockTimestamps[tokenId],
            "Token is locked"
        );

        if ((from == address(0) || to == address(0)) && batchSize == 0) {
            return;
        }
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    _contractURIMeta
                )
            );
    }

    function setContractURIMeta(
        string memory newContractURIMeta
    ) external onlyOwner {
        _contractURIMeta = newContractURIMeta;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Implement lazy minting feature
    struct LazyMint {
        uint256 tokenId;
        uint256 amount;
        address minter;
        bool executed;
        string data;
        string referralCode; // Add this line
    }

    mapping(uint256 => LazyMint) public lazyMints;
    uint256 private lazyMintCounter = 0;

    function lazyMint(
        string memory data,
        string memory referralCode // Add this parameter
    ) external whenNotPaused returns (uint256) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        lazyMints[lazyMintCounter] = LazyMint({
            tokenId: tokenId,
            amount: 1,
            minter: msg.sender,
            executed: false,
            data: data,
            referralCode: referralCode // Add this line
        });

        tokenIdToCID[tokenId] = data;

        lazyMintCounter++;

        return tokenId;
    }

    function getLazyMintedTokens() external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](lazyMintCounter);

        for (uint256 i = 0; i < lazyMintCounter; i++) {
            tokenIds[i] = lazyMints[i].tokenId;
        }

        return tokenIds;
    }

    function getExecutedLazyMintedTokens() external view returns (uint256) {
        for (uint256 i = 0; i < lazyMintCounter; i++) {
            if (lazyMints[i].executed) {
                return lazyMints[i].tokenId;
            }
        }
        return 0;
    }

    // create function to return all non-executed lazy mints in an array
    function getAvailableLazyMintedTokens() public view returns (uint256) {
        uint256 counter = 0;
        for (uint256 i = 0; i < lazyMintCounter; i++) {
            if (!lazyMints[i].executed) {
                counter++;
            }
        }
        return counter;
    }

    // create function to return all non-executed lazy mints in an array
    function getAvailableLazyMintedTokenList()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](lazyMintCounter);

        uint256 counter = 0;
        for (uint256 i = 0; i < lazyMintCounter; i++) {
            if (!lazyMints[i].executed) {
                tokenIds[counter] = lazyMints[i].tokenId;
                counter++;
            }
        }

        uint256[] memory availableTokenIds = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            availableTokenIds[i] = tokenIds[i];
        }

        return availableTokenIds;
    }

    // create a function to return the next non-executed lazy mint
    function getNextLazyMintedToken() external view returns (uint256) {
        for (uint256 i = 0; i < lazyMintCounter; i++) {
            if (!lazyMints[i].executed) {
                return lazyMints[i].tokenId;
            }
        }
        return 0;
    }

    function executeLazyMint(
        uint256 lazyMintId,
        address to,
        string memory referralCode
    ) external payable nonReentrant whenNotPaused {
        LazyMint storage _lazyMint = lazyMints[lazyMintId];
        require(!_lazyMint.executed, "Lazy mint already executed");

        uint256 finalMintPrice = minimumMintPrice;
        string memory _referralCode = "";
        uint256 netAmount = minimumMintPrice;

        // Use referralCode contract to check if the code is used
        if (
            bytes(_lazyMint.referralCode).length > 2 &&
            referralContract.isValidCode(_lazyMint.referralCode)
        ) {
            _referralCode = _lazyMint.referralCode;
        } else if (
            bytes(referralCode).length > 2 &&
            referralContract.isValidCode(referralCode)
        ) {
            _referralCode = referralCode;
        }

        // Apply referral code discount if provided
        if (bytes(_referralCode).length > 0) {
            finalMintPrice =
                minimumMintPrice -
                ((minimumMintPrice * discountRate) /
                100);
            require(msg.value >= finalMintPrice, "Insufficient payment");
            netAmount = applyDiscount(_referralCode, _lazyMint.tokenId);
        }

        require(msg.value >= finalMintPrice, "Insufficient payment");

        // Refund excess payment
        if (msg.value > finalMintPrice) {
             (bool _success, ) = payable(msg.sender).call{value: msg.value - finalMintPrice, gas: 23000}("");
             require(_success, "Refund Transfer failed");
        }
        if (isVIP) {
            referralContract.upgradeReferrer(msg.sender);
        }
        // Mint the NFT
        _safeMint(to, _lazyMint.tokenId, bytes(_lazyMint.data));
        creators[_lazyMint.tokenId] = msg.sender;
        _lazyMint.minter = msg.sender;
        // Set token URI using CID

        mintedTokens[_lazyMint.tokenId] = true;
        _setTokenCID(_lazyMint.tokenId, _lazyMint.data);
        tokenSupply[_lazyMint.tokenId] = _lazyMint.amount;
        // Emit event
        emit NFTMinted(to, _lazyMint.tokenId, 1);

        // Lock the NFT
        _lockNFT(_lazyMint.tokenId);

        // Mark the lazy mint as executed
        _lazyMint.executed = true;

        (bool success, ) = payable(treasury).call{value: netAmount, gas: 23000}("");
        require(success, "Treasury Transfer failed");

    }

    function setCreatorRoyalty(uint256 newCreatorRoyalty) external onlyOwner {
        creatorRoyalty = newCreatorRoyalty;
    }

    function setDiscountRate(uint256 newDiscountRate) external onlyOwner {
        discountRate = newDiscountRate;
    }

    /**
     * @dev Change the creator address for given token
     * @param _to   Address of the new creator
     * @param _id  Token IDs to change creator of
     */
    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id) {
        creators[_id] = _to;
    }

    /**
     * @dev Change the creator address for given tokens
     * @param _to   Address of the new creator
     * @param _ids  Array of Token IDs to change creator
     */
    function setCreator(address _to, uint256[] memory _ids) public {
        require(
            _to != address(0),
            "ERC721Tradable#setCreator: INVALID_ADDRESS."
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(_to, id);
        }
    }

    function setProxyRegistryAddress(
        address _proxyRegistryAddress
    ) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = creators[tokenId];
        royaltyAmount = (salePrice * creatorRoyalty) / 100;
    }

    function setReferralRewardPercentage(
        uint256 newReferralRewardPercentage
    ) external onlyOwner {
        referralRewardPercentage = newReferralRewardPercentage;
    }

    function setBasicReferralRewardPercentage(
        uint256 newBasicReferralRewardPercentage
    ) external onlyOwner {
        basicReferralRewardPercentage = newBasicReferralRewardPercentage;
    }

    function generateReferralCode(
        uint256 _tokenId,
        string memory _code
    ) external returns (string memory) {
        //require the user is the owner of the token
        require(
            _ownerOf(_tokenId) == msg.sender,
            "Only the owner of the token can generate a referral code"
        );
        require(
            bytes(_code).length <= 15,
            "Code length cannot exceed 15 characters"
        );
        require(
            !referralContract.isValidCode(_code),
            "The provided code is already in use"
        );

        return
            referralContract.generateReferralCode(
                msg.sender,
                _tokenId,
                address(this),
                _code
            );
    }

    function getMyReferralCode(
        address holder
    ) external view returns (string memory) {
        return referralContract.getReferralCodeByCreator(holder);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownerOf(tokenId);
    }

    // check if referral code is valid
    function isValidReferralCode(
        string memory referralCode
    ) external view returns (bool) {
        ReferralCode.Referrer memory referrer = referralContract
            .getReferrerByCode(referralCode);
        return referrer.creator != address(0);
    }

    function applyDiscount(
        string memory referralCode,
        uint256 tokenId
    ) internal returns (uint256) {
        ReferralCode.Referrer memory referrer = referralContract
            .getReferrerByCode(referralCode);
        require(referrer.creator != address(0), "Invalid referral code");
        require(referrer.creator != msg.sender, "Cannot refer yourself");
        // require(discounts[msg.sender] == 0, "Discount already applied");
        uint256 discountAmount = (minimumMintPrice * discountRate) / 100;
        uint256 netPrice = minimumMintPrice - discountAmount;

        require(msg.value >= netPrice, "Insufficient funds");

        emit DiscountApplied(msg.sender, tokenId, discountAmount);

        // Transfer the referral reward to the referrer
        uint256 _referralRewardPercentage;
        if (isVIP && !referrer.isVIP) {
            _referralRewardPercentage = basicReferralRewardPercentage;
        } else {
            _referralRewardPercentage = referralRewardPercentage;
        }

        uint256 referralReward = (netPrice * _referralRewardPercentage) / 100;
        (bool _success, ) = payable(referrer.creator).call{value:referralReward, gas: 23000}("");
        require(_success, "Reward Transfer failed");

        // Update the total discounts and applied referral codes in the ReferralCode contract
        referralContract.redeemCode(
            referralCode,
            msg.sender,
            discountAmount,
            referralReward
        );

        emit ReferralRewardSent(msg.sender, referrer.creator, referralReward);
        return netPrice - referralReward;
    }

    function getAppliedReferralCode(
        string memory referralCode
    ) public view returns (uint256) {
        ReferralCode.Referrer memory referrer = referralContract
            .getReferrerByCode(referralCode);
        require(referrer.creator != address(0), "Invalid referral code");
        // check if referrer has any applied codes
        return referralContract.getTotalAppliedReferralCodes(referrer.creator);
    }

    function getTotalRewards(address _wallet) public view returns (uint256) {
        return referralContract.totalReferralRewards(_wallet);
    }

    function getMyDiscounts() public view returns (uint256) {
        return referralContract.totalDiscountsByMinter(msg.sender);
    }

    function getAllAppliedReferralCodes()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 length = _tokenIds.current();
        address[] memory creatorsArray = new address[](length);
        uint256[] memory counts = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            address creator = creators[i + 1]; // assuming token IDs start from 1
            creatorsArray[i] = creator;
            counts[i] = referralContract.getTotalAppliedReferralCodes(creator);
        }
        return (creatorsArray, counts);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(treasury).call{value: address(this).balance, gas: 50000}("");
        require(success, "Transfer failed");
    }

    function withdrawERC20(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(treasury, balance);
    }
}
