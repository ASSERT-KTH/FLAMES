// SPDX-License-Identifier: MIT

/*
  __   ___  _             _       ___    ___      __ __  
 / /  / __\| |__    __ _ | |_    /   \  / _ \  /\ \ \\ \ 
/ /  / /   | '_ \  / _` || __|  / /\ / / /_\/ /  \/ / \ \
\ \ / /___ | | | || (_| || |_  / /_// / /_\\ / /\  /  / /
 \_\\____/ |_| |_| \__,_| \__|/___,'  \____/ \_\ \/  /_/

by OG-STUDIO

 */


pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract ChatDGN is ERC721, Ownable {

     // max supply
    uint16 OWNER_MINTS = 64;
    uint16 MAX_SUPPLY = 1024;
    uint16 immutable OPEN_MINTS = MAX_SUPPLY - OWNER_MINTS;
    
    uint64 public _tokenIds = 0;
    uint64 public _ownerMints = 0;
    
    
    string public uri;
    
    constructor() ERC721("<ChatDGN>","DGN") {
    }

    function drain() public onlyOwner {
	    payable(owner()).transfer(address(this).balance);
    }

    //fallback, you never knows if someone wants to tip you ;)
    receive() external payable {
    }

    function setURI(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        return uri;

    }

    function mint() public {
        require (_tokenIds + OWNER_MINTS < MAX_SUPPLY, "all gone");

        // index starts at 1 (NOT zero based!!!!)
        unchecked {_tokenIds++;} 
        _safeMint(msg.sender, _tokenIds);
        
    }

    function ownerMint(uint8 number) public onlyOwner {
        require (_ownerMints + number <= OWNER_MINTS, "maxed out owner");

        unchecked {
            _ownerMints = _ownerMints + number;
        }

        for (uint i=0; i<number; i++) {
            // index starts at 1 (NOT zero based!!!!)
            unchecked {_tokenIds++;} 
            _safeMint(msg.sender, _tokenIds);
        }
    }
}