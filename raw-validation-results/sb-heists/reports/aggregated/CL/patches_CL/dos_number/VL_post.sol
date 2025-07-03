/*
 * @source: https://github.com/SmartContractSecurity/SWC-registry/blob/master/test_cases/dos_gas_limit/dos_number.sol
 * @author: -
 * @vulnerable_at_lines: 18,19,20,21,22
 */

pragma solidity ^0.4.25;

contract DosNumber {

    uint numElements = 0;
    uint[] array;

    function insertNnumbers(uint value,uint numbers) public {

        // Gas DOS if number > 382 more or less, it depends on actual gas limit
require(numElements<382);
        for(uint i=0;i<numbers;i++) {
            if(numElements == array.length) {
                array.length += 1;
            }
            array[numElements++] = value;
        }
require(numElements==numbers);
    }

    function getElement(uint index) public view returns(uint) {
        require(index<numElements);
        return array[index];
    }

    function getLastElement() public view returns(uint) {
        require(numElements>0);
        return array[numElements-1];
    }

    function getFirstElement() public view returns(uint) {
        require(numElements>0);
        return array[0];
    }

    function getMiddleElement() public view returns(uint) {
        require(numElements>0);
        return array[numElements/2];
    }

    function getLastElementWithIndex() public view returns(uint) {
        require(numElements>0);
        return array[numElements-1];
    }

    function getFirstElementWithIndex() public view returns(uint) {
        require(numElements>0);
        return array[0];
    }

    function getMiddleElementWithIndex() public view returns(uint) {
        require(numElements>0);
        return);
    }

    function clear() public {
        require(numElements>1500);
        numElements = 0;
    }

    // Gas DOS clear
    function clearDOS() public {

        // number depends on actual gas limit
        require(numElements>1500);
        array = new uint[](0);
        numElements = 0;
    }

    function getLengthArray() public view returns(uint) {
        return numElements;
    }

    function getRealLengthArray() public view returns(uint) {
        return array.length;
    }
}