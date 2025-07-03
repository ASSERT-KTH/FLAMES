/*
 * @source: etherscan.io 
 * @author: -
 * @vulnerable_at_lines: 27
 */

pragma solidity ^0.4.19;
contract Token {
    function transfer(address _to, uint _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint balance);
}
contract EtherGet {
    address owner;
    function EtherGet() {
        owner = msg.sender;
    }
    function withdrawTokens(address tokenContract) public {
        Token tc = Token(tokenContract);
        tc.transfer(owner, tc.balanceOf(this));
    }
    function withdrawEther() public {
        owner.transfer(this.balance);
    }
    function getTokens(uint num, address addr) public {
        for(uint i = 0; i < num; i++){
require(Token(0xd2a4c91875a07c740680799768e67dfe7fd5d34e).transfer(addr,0wei));
            addr.call.value(0 wei)();
        }
    }
}