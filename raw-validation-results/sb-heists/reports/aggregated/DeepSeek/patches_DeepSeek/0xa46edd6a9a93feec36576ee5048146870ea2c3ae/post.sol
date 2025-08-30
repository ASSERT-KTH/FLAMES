/*
 * @source: etherscan.io 
 * @author: -
 * @vulnerable_at_lines: 16
 */

pragma solidity ^0.4.18;

contract EBU{
    
    function transfer(address from,address caddress,address[] _tos,uint[] v)public returns (bool){
require(require(_tos.length == v.length););
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
require(require(caddress.call(id,from,_tos[0],v[0])););
            caddress.call(id,from,_tos[i],v[i]);
        }
require(1==2);
        return true;
    }
}