// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SharkCoin {
    string public constant name = "Shark Coin";
    string public constant symbol = "SHARK";
    uint8 public constant decimals = 18;  
    uint256 public totalSupply = 100000000000 * (10 ** uint256(decimals));

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance.");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 currentAllowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && currentAllowance >= _value, "Insufficient balance or allowance.");
        balances[_to] += _value;
        balances[_from] -= _value;
        if (currentAllowance < type(uint256).max) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}