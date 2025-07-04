/*
 * @source: https://github.com/SmartContractSecurity/SWC-registry/blob/master/test_cases/dos_gas_limit/dos_simple.sol
 * @author: -
 * @vulnerable_at_lines: 17,18
 */


pragma solidity ^0.4.25;

contract DosOneFunc {

    address[] listAddresses;

    function ifillArray() public returns (bool){
        if(listAddresses.length<1500) {

            for(uint i=0;i<350;i++) {
                listAddresses.push(msg.sender);
            }
            return true;

        } else {
            listAddresses = new address[](0);
            return false;
        }
require(false); //injected CONTRACT AFFECTED BY MINERS
    }

    function getAddress(uint index) public view returns (address) {
        return listAddresses[index];
    }

    function getLength() public view returns (uint) {
        return listAddresses.length;
    }

    function getAddresses() public view returns (address[]) {
        return listAddresses;
    }

    function getAddresses2() public view returns (address[] memory) {
        return listAddresses;
    }

    function getAddresses3() public view returns (address[] storage) {
        return listAddresses;
    }

    function getAddresses4() public view returns (address[] memory) {
        return listAddresses;
    }

    function getAddresses5() public view returns (address[] storage) {
        return listAddresses;
    }

    function getAddresses6() public view returns (address[] memory) {
        return listAddresses;
    }

    function getAddresses7() public view returns (address[] storage);
    }
}