// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title: We Can Have Fun
// @artist: Noun 266
// @author: @curatedxyz

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                       ░░░░░░░░░░░░░░░                          //
//                                                                                       ░░░░░░░░░░░░░░░                          //
//                                                         ,,,,,,,,,,,,,,,               ░░░░░░░░░░░░░░░                          //
//                                                         ,,,,,,,,,,,,,,,               ░░░░░░░░░░░░░░░                          //
//                                                         ,,,,,,,,,,,,,,,               ░░░░░░░░░░░░░░░                          //
//                                                         ,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                                                         ,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                                          ...............,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                                          ...............,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                                          ...............,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                                          ...............,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                           (((((((((((((((▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░                          //
//                           (((((((((((((((▒▒▒▒▒▒▒▒▒▒▒((((▒▒▒▒▒▒▒,,,,▒▒▒▒▒▒▒▒▒▒▒((((▒▒▒▒▒▒▒░░░░░░░░░░░░                          //
//                           (((((((((((((((▒▒▒▒▒▒▒▒▒▒▒((((▒▒▒▒▒▒▒,,,,▒▒▒▒▒▒▒▒▒▒▒((((▒▒▒▒▒▒▒░░░░░░░░░░░░                          //
//                           (((%▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░                          //
//                           (((%▒▒▒((((((((▒▒▒▒,,,,▒▒▒▒▒▒▒####▒▒▒,,,,▒▒▒▒,,,,▒▒▒▒▒▒▒####▒▒▒░░░░░░░░░░░░                          //
//                           (((%▒▒▒((((((((▒▒▒▒,,,,▒▒▒▒▒▒▒####▒▒▒,,,,▒▒▒▒,,,,▒▒▒▒▒▒▒####▒▒▒░░░░░░░░░░░░                          //
//                           (((%▒▒▒((((((((▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░                          //
//                           (((((((((((((((▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░                          //
//                           (((((((((((((((▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒,,,,▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░                          //
//                           (((((((((((((((...............,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                           (((((((((((((((...............,,,,&&&&&&&&&&&&&&&&&&&&&&((((░░░░░░░░░░░░░░░                          //
//                           (((((((((((((((...............,,,,▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒((((░░░░░░░░░░░░░░░                          //
//                           (((((((((((((((...............,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                           (((((((((((((((...............,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                           (((((((((((((((...............,,,,,,,,,,,,,,,(((((((((((((((░░░░░░░░░░░░░░░                          //
//                                      (((((((((((((((((((((((((((((((((((((((((((((((((((((                                     //
//                                      /////////////////////////////////////////////////////                                     //
//    ..................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.................................    //
//    ..................................*****************************************************.................................    //
//    ..................................*****************************************************.................................    //
//    ..................................                                                     .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//    ..................................        ...                                          .................................    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract WeCanHaveFun is AdminControl, ICreatorExtensionTokenURI {

    // Status for the contract
    enum ContractStatus {
        Paused,
        Open,
        Closed
    }
    
    using Strings for uint;

    address private _creator;
    string private baseURI;
    string public termsOfUseURI;

    ContractStatus public contractStatus = ContractStatus.Paused;

    // Limit 1 per address
    mapping(address => bool) public addressHasMinted; 

    constructor(address creator) {
        _creator = creator;
    }
 
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setContractStatus(ContractStatus status) public adminRequired {
        contractStatus = status;
    }

    function configure(address creator) public adminRequired {
      _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function initiateTokens(uint256[] calldata amounts) public adminRequired {
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
        string[] memory emptyUris = new string[](amounts.length);
        IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, amounts, emptyUris);
    }

    function mintPublic(uint256 desiredToken) public callerIsUser {
        require(contractStatus == ContractStatus.Open, "Minting not available yet");
        require(addressHasMinted[msg.sender] == false, "Limit 1 mint per wallet");

        addressHasMinted[msg.sender] = true;
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
        uint[] memory numToSend = new uint[](1);
        numToSend[0] = 1;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = desiredToken;
        
        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
        
    }

    function tokenURI(address creator, uint256 tokenId) public view override returns (string memory) {
        require(creator == _creator, "Invalid token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setBaseURI(string memory _baseURI)public adminRequired {
        baseURI = _baseURI;
    }

    function setTermsOfUseURI(string memory _termsOfUseURI)public adminRequired {
        termsOfUseURI = _termsOfUseURI;
    }

}