// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Token.sol";

contract Bakery {

	struct Info {
		Token[] tokens;
		mapping(address => uint256) nonce;
		address template;
	}
	Info private info;


	constructor() {
		Token _template = new Token();
		_template.lock();
		info.template = address(_template);
	}
	
	function salt() public returns (bytes32) {
		return keccak256(abi.encodePacked(msg.sender, info.nonce[msg.sender]++));
	}

	function launch(bool _deployProxy, string memory _name, string memory _symbol, uint256 _totalSupply, uint256 _initialMarketCap, uint256 _transferTax, uint256 _creatorFee) external payable returns (address) {
		Token _token;
		{
			bytes32 _salt = salt();
			if (_deployProxy) {
				address _proxy;
				bytes20 _template = bytes20(info.template);
				assembly {
					let _clone := mload(0x40)
					mstore(_clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
					mstore(add(_clone, 0x14), _template)
					mstore(add(_clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
					_proxy := create2(0, _clone, 0x37, _salt)
				}
				_token = Token(_proxy);
			} else {
				_token = new Token{salt:_salt}();
			}
		}
		_token.initialize{value:msg.value}(msg.sender, _name, _symbol, _totalSupply, _initialMarketCap, _transferTax, _creatorFee);
		info.tokens.push(_token);
		return address(_token);
	}


	function template() public view returns (address) {
		return info.template;
	}
	
	function totalTokens() public view returns (uint256) {
		return info.tokens.length;
	}

	function tokenAtIndex(uint256 _index) public view returns (Token) {
		return info.tokens[_index];
	}

	function allTokens() public view returns (Token[] memory) {
		return info.tokens;
	}
}