pragma solidity >=0.6.2;
// import "lib/forge-std/src/interfaces/IERC20.sol";

interface IFullProtec {

    function getPercentSupplyStaked() external view returns (uint256);
    function setChef(address) external;

}