// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface Router {
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address, uint256, uint256, uint256, address, uint256) external payable returns (uint256, uint256, uint256);
	function swapExactETHForTokens(uint256, address[] calldata, address, uint256) external payable returns (uint256[] memory);
}

interface Factory {
	function createPair(address, address) external returns (address);
}

interface Pair {
	function balanceOf(address) external view returns (uint256);
	function transfer(address, uint256) external returns (bool);
}


contract Token {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private MAX_NAME_LENGTH = 32;
	uint256 constant private MIN_SUPPLY = 1e16; // 0.01 tokens
	uint256 constant private MAX_SUPPLY = 1e33; // 1 quadrillion tokens
	uint256 constant private PERCENT_PRECISION = 1000; // 1 = 0.1%
	Router constant private ROUTER = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	string public name;
	string public symbol;
	uint8 constant public decimals = 18;

	string constant public source = "Created with Bossman's Bakery (bakery.mullet.capital)!";


	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		bool locked;
		address pair;
		address creator;
		uint256 totalSupply;
		uint256 initialMarketCap;
		uint256 transferTax;
		uint256 creatorFee;
		mapping(address => User) users;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);

	
	function lock() external {
		require(!info.locked);
		require(totalSupply() == 0);
		info.locked = true;
	}
	
	function initialize(address _creator, string memory _name, string memory _symbol, uint256 _totalSupply, uint256 _initialMarketCap, uint256 _transferTax, uint256 _creatorFee) external payable {
		require(!info.locked);
		require(totalSupply() == 0);
		require(bytes(_name).length > 0 && bytes(_name).length <= MAX_NAME_LENGTH);
		require(bytes(_symbol).length > 0 && bytes(_symbol).length <= MAX_NAME_LENGTH);
		require(_totalSupply >= MIN_SUPPLY && _totalSupply <= MAX_SUPPLY);
		require(_initialMarketCap > 0);
		require(_transferTax < PERCENT_PRECISION);
		require(_creatorFee < PERCENT_PRECISION);
		require(msg.value >= _initialMarketCap);
		info.creator = _creator;
		name = _name;
		symbol = _symbol;
		info.totalSupply = _totalSupply;
		info.users[address(this)].balance = _totalSupply;
		emit Transfer(address(0x0), address(this), _totalSupply);
		info.initialMarketCap = _initialMarketCap;
		info.creatorFee = _creatorFee;
		_createLP();
		info.transferTax = _transferTax;
	}

	function collectTax() external {
		address _this = address(this);
		uint256 _tokens = balanceOf(_this);
		require(_tokens > 0);
		_transfer(_this, creator(), _tokens / 2);
		_transfer(_this, 0xe6c791FBd46dB3f4EdA5f7Bb76474F4FA530733E, _tokens / 3);
		_transfer(_this, 0xc28C9da0F8a500DFfC16Ff09a3DD1Cc4c530D346, _tokens / 6);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		return _approve(msg.sender, _spender, _tokens);
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		unchecked {
			uint256 _allowance = allowance(_from, msg.sender);
			require(_allowance >= _tokens);
			if (_allowance != UINT_MAX) {
				info.users[_from].allowance[msg.sender] -= _tokens;
			}
			return _transfer(_from, _to, _tokens);
		}
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}
	

	function creator() public view returns (address) {
		return info.creator;
	}

	function pair() public view returns (address) {
		return info.pair;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function initialMarketCap() external view returns (string memory) {
		return string(abi.encodePacked(_uint2str(info.initialMarketCap, 18, 5), " ETH"));
	}

	function transferTax() external view returns (string memory) {
		return string(abi.encodePacked(_uint2str(info.transferTax * 100, 3, 3), "%"));
	}

	function creatorFee() external view returns (string memory) {
		return string(abi.encodePacked(_uint2str(info.creatorFee * 100, 3, 3), "%"));
	}

	
	function _createLP() internal {
		address _this = address(this);
		address _weth = ROUTER.WETH();
		_approve(_this, address(ROUTER), totalSupply());
		info.pair = Factory(ROUTER.factory()).createPair(_weth, _this);
		( , , uint256 _lpTokens) = ROUTER.addLiquidityETH{ value: info.initialMarketCap }(_this, totalSupply(), 0, 0, _this, block.timestamp);
		Pair _pair = Pair(pair());
		if (info.creatorFee > 0) {
			_pair.transfer(creator(), _lpTokens * info.creatorFee / PERCENT_PRECISION);
		}
		_pair.transfer(address(0x0), _pair.balanceOf(_this));
		if (msg.value > info.initialMarketCap) {
			address[] memory _path = new address[](2);
			_path[0] = _weth;
			_path[1] = _this;
			ROUTER.swapExactETHForTokens{ value: msg.value - info.initialMarketCap }(0, _path, creator(), block.timestamp);
		}
	}
	
	function _approve(address _owner, address _spender, uint256 _tokens) internal returns (bool) {
		info.users[_owner].allowance[_spender] = _tokens;
		emit Approval(_owner, _spender, _tokens);
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		unchecked {
			require(_tokens > 0);
			require(balanceOf(_from) >= _tokens);
			address _this = address(this);
			if (info.transferTax == 0 || _from == _this || _to == _this || _from == creator()) {
				info.users[_from].balance -= _tokens;
				info.users[_to].balance += _tokens;
				emit Transfer(_from, _to, _tokens);
			} else {
				info.users[_from].balance -= _tokens;
				uint256 _tax = _tokens * info.transferTax / PERCENT_PRECISION;
				info.users[_this].balance += _tax;
				emit Transfer(_from, _this, _tax);
				info.users[_to].balance += _tokens - _tax;
				emit Transfer(_from, _to, _tokens - _tax);
			}
			return true;
		}
	}


	function _uint2str(uint256 _value, uint256 _scale, uint256 _maxDecimals) internal pure returns (string memory str) {
		uint256 _d = _scale > _maxDecimals ? _maxDecimals : _scale;
		uint256 _n = _value / 10**(_scale > _d ? _scale - _d : 0);
		if (_n == 0) {
			return "0";
		}
		uint256 _digits = 1;
		uint256 _tmp = _n;
		while (_tmp > 9) {
			_tmp /= 10;
			_digits++;
		}
		_tmp = _digits > _d ? _digits : _d + 1;
		uint256 _offset = (_tmp > _d + 1 ? _tmp - _d - 1 > _d ? _d : _tmp - _d - 1 : 0);
		for (uint256 i = 0; i < _tmp - _offset; i++) {
			uint256 _dec = i < _tmp - _digits ? 0 : (_n / (10**(_tmp - i - 1))) % 10;
			bytes memory _char = new bytes(1);
			_char[0] = bytes1(uint8(_dec) + 48);
			str = string(abi.encodePacked(str, string(_char)));
			if (i < _tmp - _d - 1) {
				if ((i + 1) % 3 == (_tmp - _d) % 3) {
					str = string(abi.encodePacked(str, ","));
				}
			} else {
				if ((_n / 10**_offset) % 10**(_tmp - _offset - i - 1) == 0) {
					break;
				} else if (i == _tmp - _d - 1) {
					str = string(abi.encodePacked(str, "."));
				}
			}
		}
	}
}