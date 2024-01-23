// https://twitter.com/bitcashtoken1
// https://t.me/bitcashtoken1
// web soon...

// Embrace the Power of Memes BitCash is designed to bring the community together through the shared love of memes and crypto
//Whether you're a meme creator, a crypto investor, or just a meme enthusiast, BitCash is the token for you!

// 4% or 5% will be allocated to a wallet for potential listings on CEX and marketing.
 
//BBBBBBBBBBBBBBBBB   iiii                          CCCCCCCCCCCCC
//B::::::::::::::::B i::::i                       CCC::::::::::::C
//B::::::BBBBBB:::::B  iiii                     CC:::::::::::::::C
//BB:::::B     B:::::B                          C:::::CCCCCCCC::::C
//B::::B     B:::::Biiiiiii     tttttttttttttt   C:::::C       CCCCCC
  // B::::B     B:::::Bi:::::i     t:::::::::::::::::C:::::C
  //B::::BBBBBB:::::B  i::::i     t:::::::::::::::::C:::::C
  //B:::::::::::::BB   i::::i     ttttttt:::::::tttC:::::C
  //B::::BBBBBB:::::B  i::::i           t:::::t  C:::::C
  //B::::B     B:::::B i::::i           t:::::t  C:::::C       CCCCCC
  //B::::B     B:::::B i::::i           t:::::t  C:::::CCCCCCCC::::C
  //B::::B     B:::::Bi::::::i          t::::::tC:::::::::::::::C
//BB:::::BBBBBB::::::Bi::::::i          t::::::t CC::::::::::::C
//B:::::::::::::::::B i::::::i          t::::::t   CCC:::::::::C
//B::::::::::::::::B  i::::::i          t::::::t      CCCCCCCCC
//BBBBBBBBBBBBBBBBB   iiiiiiii          ttttttt




// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract bitcash {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private contractOwner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensBurned(address indexed burner, uint256 value);
    event ContractRenounced(address indexed previousOwner);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        require(_totalSupply > 0, "Total supply must be greater than zero");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        balanceOf[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);

        contractOwner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient");

        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid spender");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        require(_to != address(0), "Invalid recipient");

        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit TokensBurned(msg.sender, _value);
        return true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");

        emit OwnershipTransferred(contractOwner, _newOwner);
        contractOwner = _newOwner;
    }

    function renounceContractOwnership() public onlyOwner {
        emit ContractRenounced(contractOwner);
        contractOwner = address(0);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid recipient");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(balanceOf[_to] + _value >= balanceOf[_to], "Integer overflow"); // Check for integer overflow

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
    }
}