/*
𝕝𝐢ˢ𝓽𝔼ή. к卂𝓞𝐌ⓞ𝔧Ｉ ѕⓞ 𝐭ι𝓻Ẹ𝐝 𝓞ⓕ 𝓉Ｈ𝓘𝕤 ᗰ𝐚я𝓴Ｅ𝕥. 𝔼ｘᕼ𝔞υѕ𝕋𝐄đ. ｋ𝕒𝐨𝕞𝓸ڶＩ ⓦᗩᑎ𝐭Ｓ 𝐲ㄖ𝓾 𝕋ｏ Ŧ𝔦ｎ𝐃 ά ק𝔩Ã𝓒ⓔ т𝕆 ⓕ𝓾Čᛕ 𝓪ℝᵒᑌⓝ𝓭. 𝓫є 𝐟𝐫乇ᵉ. 𝕕𝔬𝓝𝕋 千乇ａŘ.
0/0 
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 

contract ITSSOOVERWEARESOBACK is ERC20, ERC20Burnable, Ownable {
      
    constructor()
        ERC20(unicode"ITSSOOVERWEARESOBACK", unicode"KAO") 
    {
        address supplyRecipient = 0xffB2D0a783c395F9FdF3AB91d15e91b7309354B2;
        
        _mint(supplyRecipient, 10000000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xffB2D0a783c395F9FdF3AB91d15e91b7309354B2);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}
