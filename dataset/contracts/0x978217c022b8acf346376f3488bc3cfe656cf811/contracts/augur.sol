// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
@author smashice.eth
@checkout dtech.vision and hupfmedia.de
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░▒▓▒▓░░▒█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░▓▒▓▒█▒▓▒█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░▒▓░▓▒▓▒▓░▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░▒▓░▓▒▓▒▓░▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░▓░▓▒▓▒▒▓▓▒▓░▓███████████████░░░▓█████████████▒░░▓█████████████▓░░██░░░░░░░░░░░░█▓░░░
░░░░░░▓░▒░▒░▒██▒▓░░░░░░░░▓█░░░░░░░░░██░░░░░░░░░░░░░░░▒█▒░░░░░░░░░░░░░░░██░░░░░░░░░░░░█▓░░░
░░░░░▒▓████████▒▓░░░░░░░░▓█░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒█▒░░░░░░░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒█▓░░░
░░░░▒██▒▒▓▒▒▒██▒▓░░░░░░░░▓█░░░░░░░░░██▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒█▒░░░░░░░░░░░░░░░██▓▓▓▓▓▓▓▓▓▓▓▓█▓░░░
░░░▒▒██▒▓░▒▓░██▒▒░░░░░░░░▓█░░░░░░░░░██░░░░░░░░░░░░░░░▒█▒░░░░░░░░░░░░░░░██░░░░░░░░░░░░█▓░░░
░░░▒▒▓█████████▒░░░░░░░░░▓█░░░░░░░░░▒█▓▓▓▓▓▓▓▓▓▓▓▓▓░░░██▓▓▓▓▓▓▓▓▓▓▓▓▒░░██░░░░░░░░░░░░█▓░░░
░░░▒▓░▒░▒░▒░▒░▒░░░░░░░░░░▒▒░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒░░░░░░░░░░░░▒░░░░
░░░▒▓░▓░▓▒▓▒▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░▒░▓░▓▒▓▒▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░▓░▓▒▓░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░▓▒▓░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721-templates/chirulabsERC721A.sol";

contract Augur is chirulabsERC721A { 
    event Received(address, uint);
    // see https://docs.soliditylang.org/en/latest/contracts.html#receive-ether-function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    using Strings for uint;
    /**
     * @param name The NFT collection name
     * @param symbol The NFT collection symbol
     * @param receiver The wallet address to recieve the royalties
     * @param feeNumerator Numerator of royalty % where Denominator default is 10000
     */
    constructor (
        string memory name, 
        string memory symbol,
        address receiver,
        uint96 feeNumerator
        ) 
    chirulabsERC721A(name, symbol, receiver, feeNumerator)
    {
        fundReciever = receiver;
        _safeMint(0x5D7D6e4c6293e1c31A588133016827aC5920501E, 8);
        _safeMint(0x75F025606496bF75DDFe94BC912C42B48B0241c0, 8);

        initCards();
    }

    address internal fundReciever;

    uint8 public burnState = 0;
    bool public burnActive = false;
    bool public mintActive = false;
    bool private payingOut = false;

    string public baseURI1 = "ar://r7UGzRyCXkCob3tv23gw3Qe2sAYup6aG5ykcwkRDprs/";
    string public baseURI2 = "ar://0SIxU-WtHTsvjlyTO7rZl6gq0Y9DXQYYYQf4i7ouDB4/";
    string public baseURI3 = "ar://7_3YkgijnGn2B9s-D7axZVF_pEhALJ33Jy6guJfKmys/";
    string public baseURI4 = "ar://haN6isUXg_EPczVHL5uxeZVtiU-XlFkwqa3IVoggfyE/";
    string public baseURI5;

    uint128 public MAX_SUPPLY = 150; 
    uint128 public cardsLeft = 150;
    uint128[150] private cards;

    mapping(address => uint256) presalebook;
    mapping(uint256 => uint8) public tokenPhase;
    mapping(uint256 => uint256) tokenAlias;

    /**
     * Allows owner to send aribitrary amounts of tokens to arbitrary adresses in last stage
     * @param recipient Array of addresses of which recipient[i] will recieve amount [i]
     * @param amount Array of integers of which amount[i] will be airdropped to recipient[i]
     */
    function airdrop(
        address[] memory recipient,
        uint256[] memory amount
    )
    public onlyOwner
    {
        require(burnState == 4, "Be patient.");
        for(uint i = 0; i < recipient.length; ++i)
        {
            require(totalSupply() + (amount[i]) <= MAX_SUPPLY, "705 no more token available");
            uint256 start = totalSupply();
            _safeMint(recipient[i], amount[i]);
            for(uint256 j = 0; j < amount[i]; ++j)
            {
                tokenPhase[start + j] = 4;
            }
        }
    }

    /**
     * If mint is active, set it to not active.
     * If mint is not active, set it to active.
     */
    function flipMintState() 
    public onlyOwner
    {
        mintActive = !mintActive;
    }

    /**
     * Allows you to buy tokens
     * @param amount_ amount of tokens to get
     */
    function mint(
        uint256 amount_
    ) 
    public payable 
    {
        require(mintActive, "702 Feature disabled/not active"); 
        require(burnState == 0, "Burn started");

        presalebook[msg.sender] = presalebook[msg.sender] + amount_;
        require(presalebook[msg.sender] <= 2, "Already claimed");

        require(msg.sender == tx.origin, "don't try...");
        require(totalSupply() + (amount_) <= MAX_SUPPLY, "705 no more token available"); 

        _safeMint(msg.sender, amount_); 
    }

    /**
     * Allows owner to finish minting and mint all remaining tokens to themselves
     */
    function closeMint() 
    public onlyOwner {
        mintActive = false;
        uint256 rest = MAX_SUPPLY - totalSupply();
        uint256 one = rest / 2;
        _safeMint(0x5D7D6e4c6293e1c31A588133016827aC5920501E, one);
        _safeMint(0x75F025606496bF75DDFe94BC912C42B48B0241c0, rest - one);
    }

    /**
     * burn changes tokenPhase if eligable
     * @param tokenId_ the token to evolve
     */
    function burn(
        uint256 tokenId_
    )
    public
    {
        require(burnActive && burnState < 3, "702 Feature disabled/not active");
        require(_exists(tokenId_), "704 Query for nonexistent token");
        require(msg.sender == ownerOf(tokenId_), "not your token");
        uint8 phase = tokenPhase[tokenId_];
        require(phase == burnState, "Token not in proper phase");
        
        tokenPhase[tokenId_] = phase+1;
        //draw lucky number as "new" TokenId
        tokenAlias[tokenId_] = draw(); 
    }

    /**
     * Allows owner to switch burning to the next phase
     */
    function incrementBurn(
    ) 
    public onlyOwner
    {
        require(!burnActive, "Can't increment while burn is active!");
        require(burnState < 3, "Be patient.");
        burnState++;
        initCards();
    }

    function startPhase5(
        uint128 size,
        string memory baseURI5_
    ) public onlyOwner
    {
        require(burnState == 3, "Be patient.");
        require(totalSupply() == MAX_SUPPLY, "Close mint first!");
        MAX_SUPPLY = MAX_SUPPLY + size;
        baseURI5 = baseURI5_;
        burnState = 4;
    }

    /**
     * Allows owner to toggle burning on/off
     */
    function flipBurnActive(
    ) 
    public onlyOwner
    {
        burnActive = !burnActive;
    }

    /**
     * Allows owner to withdraw all ETH
     */
    function withdraw()
    public 
    {
        payingOut = true;
        uint256 total = address(this).balance;
        uint256 bal =  total / 2;
        (bool success, ) = payable(0x5D7D6e4c6293e1c31A588133016827aC5920501E).call{value: bal}(""); 
        require(success, "Transfer failed!");
        (success, ) = payable(0x75F025606496bF75DDFe94BC912C42B48B0241c0).call{value: (total - bal)}(""); 
        require(success, "Transfer failed!");
        payingOut = false;
    }

    /**
     * Allows owner to set reciever of withdrawl
     * @param reciever who to recieve the balance of the contract
     */
    function setReciever(address reciever)
    public onlyOwner
    {
        fundReciever = reciever;
    }

    /**
     * Allows owner to set baseURI for all tokens
     * @param newBaseURI1_ new baseuri to be used in tokenuri generation of phase 0
     * @param newBaseURI2_ new baseuri to be used in tokenuri generation of phase 1
     * @param newBaseURI3_ new baseuri to be used in tokenuri generation of phase 2
     * @param newBaseURI4_ new baseuri to be used in tokenuri generation of phase 3
     * @param newBaseURI5_ new baseuri to be used in tokenuri generation of phase 4
     */
    function setBaseURI(
        string calldata newBaseURI1_,
        string calldata newBaseURI2_,
        string calldata newBaseURI3_,
        string calldata newBaseURI4_,
        string calldata newBaseURI5_
    ) external onlyOwner 
    {
        baseURI1 = newBaseURI1_;
        baseURI2 = newBaseURI2_;
        baseURI3 = newBaseURI3_;
        baseURI4 = newBaseURI4_;
        baseURI5 = newBaseURI5_;
    }

    /**
     * Allows owner to set new EIP2981 Royalty share and/or reciever for the whole collection
     * @param reciever_ new royalty reciever to be used
     * @param feeNumerator_ new royalty share in basis points to be used e.g. 100 = 1%
     */
    function setRoyalty(
        address reciever_,
        uint96 feeNumerator_
    ) public onlyOwner
    {
        _setDefaultRoyalty(reciever_, feeNumerator_);
    }

    /**
     * Returns the URI (Link) to the given tokenId
     * @param tokenId_ tokenId of which to get the URI
     */
    function tokenURI(
        uint tokenId_
    ) public override view
    returns (string memory)
    {
        require(_exists(tokenId_), "704 Query for nonexistent token");

        uint8 _phase = tokenPhase[tokenId_];
        uint256 metadataID = _phase == 0 ? tokenId_ : tokenAlias[tokenId_]; // if phase 0 use tokenId, else use alias
        string memory _baseURI = _phase == 0 ? baseURI1 : _phase == 1 ? baseURI2
                               : _phase == 2 ? baseURI3 : _phase == 3 ? baseURI4
                               : baseURI5;
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, metadataID.toString(), '.json')) : "https://dtech.vision";
    }

    /**
     * Facilitates drawing a random number without replacement
     * @return uint128 pseudo random number out of numbers left
     */
    function draw(
    )
    private returns(
        uint128
    )
    {
        require(cardsLeft > 0, "Can't draw anymore.");
        uint128 i = uint128(block.prevrandao % cardsLeft);
        uint128 out = cards[i];
        cards[i] = cards[cardsLeft -1];
        cards[cardsLeft -1] = cardsLeft;
        cardsLeft -= 1;
        return out;
    }

    /** init all cards and reset cardsLeft
     */
    function initCards()
    private {
        cardsLeft = 150;
        for(uint128 i = 0; i < cards.length; ++i)
        {
            cards[i] = i;
        }
    }
}
