// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";

contract FeatureKeys is Ownable {
    struct FeatureKey {
        string featureName;
        string userApiKey;
        string secretKey;
        uint256 expiresAt; // Unix timestamp
        bool active;
    }

    mapping(uint256 => FeatureKey[]) private _featureKeys;

    function addFeatureKey(
        uint256 tokenId,
        string memory featureName,
        string memory userApiKey,
        string memory secretKey,
        uint256 expiresAt
    ) public onlyOwner {
        _featureKeys[tokenId].push(
            FeatureKey(featureName, userApiKey, secretKey, expiresAt, true)
        );
    }

    function getFeatureKey(
        uint256 tokenId,
        uint256 index
    )
        public
        view
        returns (
            string memory featureName,
            string memory userApiKey,
            string memory secretKey,
            uint256 expiresAt,
            bool active
        )
    {
        require(
            _featureKeys[tokenId].length > index,
            "No feature key set for this token at the given index"
        );
        return (
            _featureKeys[tokenId][index].featureName,
            _featureKeys[tokenId][index].userApiKey,
            _featureKeys[tokenId][index].secretKey,
            _featureKeys[tokenId][index].expiresAt,
            _featureKeys[tokenId][index].active
        );
    }

    function getTokenFeatureKeys(
        uint256 tokenId
    ) public view returns (FeatureKey[] memory) {
        return _featureKeys[tokenId];
    }

    function deleteFeatureKey(uint256 tokenId, uint256 index) public onlyOwner {
        require(
            _featureKeys[tokenId].length > index,
            "No feature key set for this token at the given index"
        );
        delete _featureKeys[tokenId][index];
    }

    function updateFeatureKey(
        uint256 tokenId,
        uint256 index,
        string memory featureName,
        string memory userApiKey,
        string memory secretKey,
        uint256 expiresAt,
        bool active
    ) public onlyOwner {
        require(
            _featureKeys[tokenId].length > index,
            "No feature key set for this token at the given index"
        );
        _featureKeys[tokenId][index] = FeatureKey(
            featureName,
            userApiKey,
            secretKey,
            expiresAt,
            active
        );
    }
}
