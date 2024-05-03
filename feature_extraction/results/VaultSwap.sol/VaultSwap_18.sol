// File: ../sc_datasets/DAppSCAN/BlockSec-blocksec_alpaca_v1.0_signed/bsc-alpaca-contract-cb13e32fe5a4ba6f63b0235bd4624715592e4abe/contracts/5/protocol/apis/wault/WaultSwapFactory.sol
/**
 *Submitted for verification at BscScan.com on 2021-04-17
 */
// SPDX-License-Identifier: MIТ
pragma solidity =0.5.16;
interface IWaultSwapFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint256) external view returns (address pair);
  function allPairsLength() external view returns (uint256);
  function createPair(address tokenA, address tokenB) external returns (address pair);
  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}
interface IWaultSwapPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint256);
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);
  function MINIMUM_LIQUIDITY() external pure returns (uint256);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
  function price0CumulativeLast() external view returns (uint256);
  function price1CumulativeLast() external view returns (uint256);
  function kLast() external view returns (uint256);
  function mint(address to) external returns (uint256 liquidity);
  function burn(address to) external returns (uint256 amount0, uint256 amount1);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
  function skim(address to) external;
  function sync() external;
  function initialize(address, address) external;
}
interface IWaultSwapERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint256);
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
  }
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
  }
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
  }
}
contract WaultSwapERC20 is IWaultSwapERC20 {
  using SafeMath for uint256;
  string public constant name = "WaultSwap LP";
  string public constant symbol = "WLP";
  uint8 public constant decimals = 18;
  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint256) public nonces;
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  constructor() public {
  }
  function _mint(address to, uint256 value) internal {
  }
  function _burn(address from, uint256 value) internal {
  }
  function _approve(
    address owner,
    address spender,
    uint256 value
  ) private {
  }
  function _transfer(
    address from,
    address to,
    uint256 value
  ) private {
  }
  function approve(address spender, uint256 value) external returns (bool) {
  }
  function transfer(address to, uint256 value) external returns (bool) {
  }
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool) {
  }
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
  }
}
// a library for performing various math operations
library Math {
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
  }
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint256 y) internal pure returns (uint256 z) {
  }
}
// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
library UQ112x112 {
  uint224 constant Q112 = 2**112;
  // encode a uint112 as a UQ112x112
  function encode(uint112 y) internal pure returns (uint224 z) {
  }
  // divide a UQ112x112 by a uint112, returning a UQ112x112
  function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
  }
}
interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}
interface IWaultSwapCallee {
  function waultSwapCall(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}
contract WaultSwapPair is IWaultSwapPair, WaultSwapERC20 {
  using SafeMath for uint256;
  using UQ112x112 for uint224;
  uint256 public constant MINIMUM_LIQUIDITY = 10**3;
  bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
  address public factory;
  address public token0;
  address public token1;
  uint112 private reserve0; // uses single storage slot, accessible via getReserves
  uint112 private reserve1; // uses single storage slot, accessible via getReserves
  uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves
  uint256 public price0CumulativeLast;
  uint256 public price1CumulativeLast;
  uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
  uint256 private unlocked = 1;
  modifier lock() {
  }
  function getReserves()
    public
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint32 _blockTimestampLast
    )
  {
  }
  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) private {
  }
  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);
  constructor() public {
  }
  // called once by the factory at time of deployment
  function initialize(address _token0, address _token1) external {
  }
  // update reserves and, on the first call per block, price accumulators
  function _update(
    uint256 balance0,
    uint256 balance1,
    uint112 _reserve0,
    uint112 _reserve1
  ) private {
  }
  // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
  function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
  }
  // this low-level function should be called from a contract which performs important safety checks
  function mint(address to) external lock returns (uint256 liquidity) {
  }
  // this low-level function should be called from a contract which performs important safety checks
  function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
  }
  // this low-level function should be called from a contract which performs important safety checks
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external lock {
  }
  // force balances to match reserves
  function skim(address to) external lock {
  }
  // force reserves to match balances
  function sync() external lock {
  }
}
contract WaultSwapFactory is IWaultSwapFactory {
  bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(WaultSwapPair).creationCode));
  address public feeTo;
  address public feeToSetter;
  mapping(address => mapping(address => address)) public getPair;
  address[] public allPairs;
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
  constructor(address _feeToSetter) public {
  }
  function allPairsLength() external view returns (uint256) {
  }
  function createPair(address tokenA, address tokenB) external returns (address pair) {
    require(tokenA != tokenB, "WaultSwap: IDENTICAL_ADDRESSES");
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "WaultSwap: ZERO_ADDRESS");
    require(<FILL_ME>); // single check is sufficient
    bytes memory bytecode = type(WaultSwapPair).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    assembly {
      pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    IWaultSwapPair(pair).initialize(token0, token1);
    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair; // populate mapping in the reverse direction
    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length);
  }
  function setFeeTo(address _feeTo) external {
  }
  function setFeeToSetter(address _feeToSetter) external {
  }
}