// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ReferralCode is Ownable {
    struct Referrer {
        string code;
        address creator;
        uint256 tokenId;
        address tokenAddress;
        uint256 totalAppliedCodes;
        uint256 totalRewards;
        bool isVIP;
    }

    event ReferralCodeGenerated(string code, address creator);
    event ReferralCodeRedeemed(string code, address minter);
    event ReferrerUpgraded(string code, address creator);

    mapping(string => Referrer) public referralCodes;
    mapping(string => bool) public referralCodesVIP;
    mapping(address => string) public referralCodesByCreator;
    string[] public referralCodeKeys;
    mapping(address => uint256) public totalReferralRewards;
    mapping(address => uint256) public totalAppliedReferralCodes;
    mapping(address => uint256) public totalDiscountsByMinter;
    mapping(address => address) public nftContracts;
    mapping(address => bool) public nftContractVIP;

    uint256 public totalDiscounts;
    uint256 public totalReferralCount;
    uint256 public totalRewards;

    modifier onlyNFTContract() {
        require(
            nftContracts[msg.sender] == msg.sender,
            "Only NFT contract can call this function"
        );
        _;
    }

    function addNFTContract(
        address _nftContract,
        bool isVIP
    ) external onlyOwner {
        nftContracts[_nftContract] = _nftContract;
        nftContractVIP[_nftContract] = isVIP;
    }

    function removeNFTContract(address _nftContract) external onlyOwner {
        delete nftContracts[_nftContract];
        delete nftContractVIP[_nftContract];
    }

    function generateReferralCode(
        address _creator,
        uint256 _tokenId,
        address _tokenAddress,
        string memory _code
    ) external onlyNFTContract returns (string memory) {
        require(_creator != address(0), "Creator address cannot be 0");
        string memory code;
        if (bytes(_code).length > 0) {
            require(
                _isValidCode(_code),
                "The provided code contains invalid characters"
            );
            require(!isValidCode(_code), "The provided code is already in use");
            code = _code;
        } else {
            code = generateUniqueReferralCode();
        }
        bool _vip = nftContractVIP[_tokenAddress];
        referralCodes[code] = Referrer(
            code,
            _creator,
            _tokenId,
            _tokenAddress,
            0,
            0,
            _vip
        );
        referralCodesVIP[code] = _vip;
        referralCodeKeys.push(code);
        referralCodesByCreator[_creator] = code;
        emit ReferralCodeGenerated(code, _creator);
        return code;
    }

    function isValidCode(string memory _code) public view returns (bool) {
        return referralCodes[_code].creator != address(0);
    }

    function upgradeReferrer(
        address _referrer
    ) external onlyNFTContract returns (Referrer memory) {
        require(_referrer != address(0), "Referrer address cannot be 0");
        string memory _code = referralCodesByCreator[_referrer];
        Referrer storage referrer = referralCodes[_code];
        if (bytes(_code).length > 0) {
            // require(referrer.creator != address(0), "Referrer does not exist");
            if (referrer.isVIP) {
                return referrer;
            } else {
                referrer.isVIP = true;
                emit ReferrerUpgraded(_code, _referrer);
            }
            return referrer;
        } else {
            return referrer;
        }
    }

    function redeemCode(
        string memory _code,
        address _minter,
        uint256 _discount,
        uint256 _reward
    ) external onlyNFTContract returns (Referrer memory) {
        Referrer storage referrer = referralCodes[_code];
        require(referrer.creator != address(0), "Invalid referral code");
        require(referrer.creator != _minter, "Cannot refer yourself");
        referrer.totalAppliedCodes++;
        referrer.totalRewards += _reward;

        totalDiscounts += _discount;
        totalReferralCount++;
        totalRewards += _reward;

        totalReferralRewards[referrer.creator] += _reward;
        totalAppliedReferralCodes[referrer.creator]++;
        totalDiscountsByMinter[_minter] += _discount;

        emit ReferralCodeRedeemed(_code, _minter);

        return referrer;
    }

    function getReferralCodeByCreator(
        address creator
    ) external view returns (string memory) {
        return referralCodesByCreator[creator];
    }

    function getReferrerByCode(
        string memory _code
    ) external view returns (Referrer memory) {
        Referrer storage referrerStorage = referralCodes[_code];
        require(referrerStorage.creator != address(0), "Invalid referral code");

        Referrer memory referrerMemory = Referrer({
            code: referrerStorage.code,
            creator: referrerStorage.creator,
            tokenId: referrerStorage.tokenId,
            tokenAddress: referrerStorage.tokenAddress,
            totalAppliedCodes: referrerStorage.totalAppliedCodes,
            totalRewards: referrerStorage.totalRewards,
            isVIP: referrerStorage.isVIP
        });

        return referrerMemory;
    }

    function getTotalAppliedReferralCodes(
        address creator
    ) external view returns (uint256) {
        return totalAppliedReferralCodes[creator];
    }

    function generateUniqueReferralCode()
        internal
        view
        returns (string memory)
    {
        string memory code;
        do {
            code = randomString(8);
        } while (isValidCode(code));
        return code;
    }

    function _isValidCode(string memory _code) internal pure returns (bool) {
        bytes memory b = bytes(_code);
        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !((char >= bytes1("0") && char <= bytes1("9")) ||
                    (char >= bytes1("A") && char <= bytes1("Z")) ||
                    (char >= bytes1("a") && char <= bytes1("z")))
            ) {
                return false;
            }
        }
        return true;
    }

    function randomString(uint256 length) public view returns (string memory) {
        string memory chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        bytes memory charsBytes = bytes(chars);
        bytes memory str = new bytes(length);
        for (uint256 i = 0; i < length; ++i) {
            uint256 rand = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        blockhash(block.number - 1),
                        i
                    )
                )
            ) % charsBytes.length;
            str[i] = charsBytes[rand];
        }
        return string(str);
    }


}
