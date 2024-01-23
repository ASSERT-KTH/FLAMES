// SPDX-License-Identifier: MIT




/*

@B7?G@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P~.!&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
B:   7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!    ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
7     .?PGB#######&@@@@@@@@@@@@@@#GBB###BBGGJ     :~#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@#PJ~.      ......^B@@@@@@@@@@@@G.           ^7JPB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@&P.           .G@@@@@@@@@@5            !@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@:            .B@@@@@@@@J             7@@@@@@@@@@@@@@@@@@@@@@@@@@@GJYYYYYYYYYYYYYYYY5PB&@@@@@@
@@@@@@&:             :#@@@@@&7              7@@@BBGPP5Y?7#@@#BBGP5J7^5@@#?.       .Y55Y?~    .~Y#@@@
@@@@@@&:   !:         ~@@@@#~   .Y.         7@@@J:       P@@B!       7@@@@!       7@@@@@@#J.    .!B@
@@@@@@&:   5#:         ?@@G:   :B&.         7@@@@P       5@@@@^      7@@@@!       ?@@@@@@@@G.     .5
@@@@@@&:   Y@#:         P5    ^#@&:         7@@@@#       Y@@@@~      7@@@@!       ?@@@@@@@@@?      .
@@@@@@&:   Y@@B.             ^#@@&:         7@@@@#.      Y@@@@!      7@@@@!       ?@@@@@@@@@Y      :
@@@@@@&:   Y@@@P            ~&@@@&:         7@@@@B       Y@@@@^      !@@@@!       ?@@@@@@@@@!      Y
@@@@@@&:   Y@@@@Y          ~&@@@@&.         7@@@@&:      ~B&@G.      ~@@@@!       ?@@@@@@@@Y      ?@
@@@@@@@:   5@@@@@?        !@@@@@@B          7@@@@@5        .::       :&@@@!       ?@@@@@@B!     ~P@@
@@@@@&P.   ?#&@@@@?      7@@@@@@@J          ~#&@@@@G?~^^^^~?P&Y^^^^~~~JP#P:       :?55Y7^..:~7YB@@@@
@@@@J^.    .:^P@@@@J    ?@@@@@B~^      ....::^!?#@@@@@@@@@@@@@@@@@@@@@@@GJY55555555Y555PGB#&@@@@@@@@

Shrek is love, Shrek is life,
Owning a Mud token, void of strife.
In green-hued swamps, our hearts do trek,
Bound in joy, in the world of Shrek.

🌎 https://www.mudcoin.xyz/
💬 https://twitter.com/muddedxyz
💬 https://t.me/muderc

Pepe lives in the past. It's time for $MUD to rise out of the swamp... */





pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Mud is Ownable, ERC20 {
    address public uniswapV2Pair;

    constructor() ERC20("Mud", "MUD") {
        _mint(msg.sender, 69_420_000_000_000 * 10**18);
    }

    function setRule(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading has yet to descend into the swamps of commerce");
            return;
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}