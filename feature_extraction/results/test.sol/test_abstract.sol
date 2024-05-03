/*
 * Pragmas
 */

pragma solidity 0.4.4;
pragma solidity ^0.4.4;
pragma solidity ~0.4.4;
pragma solidity >0.4.4;
pragma solidity >=0.4.4;
pragma solidity <0.4.4;
pragma solidity <=0.4.4;
pragma solidity =0.4.4;
pragma solidity 0.4;
pragma solidity >=0.5.0 <0.7.0;
pragma solidity ^0.6;
pragma solidity ^0.5.0 || ^0.6.0;
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;
pragma experimental ABIEncoderV2;

/*
 * Imports
 */

import "./abc.sol";
import "./def.sol";
import "./abc.sol" as x;
import * as y from "./abc.sol";
import {a as b, c as d, f} from "./abc.sol";
import './abc.sol' as my_abc;
import { a as my_a, b as my_b } from './abc.sol';
import * as abc from './abc.sol';

/*
 * Enums
 */

enum Locations {
    Continent,
    Empire,
    Union,
    Country,
    State,
    City,
    Council,
    Village
}

event E();

contract c {
    enum foo { }
    enum validEnum { Value1, Value2, Value3, Value4 }
}

/*
 * Top-level functions
 */

function helper(uint x) pure returns (uint) {
                 
}

/*
 * Top-level structs
 */

struct KeyValuePair {
    string name;
    int256 value;
}

struct GlobalBaseStruct {
    KeyValuePair[] pairs;
    Locations location;
}

/*
 * Constants
 */

uint constant topLevelConstantVariable = 3;

/*
 * Custom errors
 */

error TopLevelCustomError();
error TopLevelCustomErrorWithArg(uint x);
error TopLevelCustomErrorArgWithoutName(string);

contract CustomErrors {
  error ContractCustomError();
  error ContractCustomErrorWithArg(uint x);
  error ContractCustomErrorArgWithoutName(string);

  function throwCustomError() {
                                 
  }
}

/*
 * User-defined value types
 */

type Price is uint128;
type Quantity is uint128;
type UFixed is uint256;

contract Foo {
  type Id is uint8;

  Id public id;
}

/*
 * Strings
 */

contract test {
    string a = hex"00FF0000";
    string b = hex'00AA0000';
    string b = hex'00AA_0000';
    string b = hex"";
    string a = "aaa"
    "bbb";
    string b = "aaa""bbb";
    string c = "aaa"  "bbb";

    // unicode strings
    string a = unicode"Hello 😃";
    string b = unicode'Hello 😃';

    // hex literal parts
    function foo() public {
                                          
                            
    }
}

/*
 * Libraries
 */

library a {}
library b {}
library c {}
library f {}

library Lib {
}

library Lib {
    function f() { }
}

library FixedMath {
    uint constant multiplier = 10**18;

    function add(UFixed a, UFixed b) internal pure returns (UFixed) {
                                                                
    }

    function mul(UFixed a, uint256 b) internal pure returns (UFixed) {
                                                 
    }

    function floor(UFixed a) internal pure returns (uint256) {
                                             
    }

    function toUFixed(uint256 a) internal pure returns (UFixed) {
                                           
    }
}

/*
 * Assembly
 */

contract BooleanLiteralsInAssembly {
  function f() {
           
              
               
                
     
  }
}

/*
 * Etc
 */

contract test {
    function f(uint a, uint b);
    function g(uint c);
}
contract c {
    event e(uint[10] a, bytes7[8] indexed b, c[3] x);
}
contract c {
    function f() {
                        
    }
}
contract c {
    uint[10] a;
    uint[] a2;
    struct x { uint[2**20] b; y[0] c; }
    struct y { uint d; mapping(uint=>x)[] e; }
}
contract test {
    function fun(uint256 a) {
                                                   
    }
}

contract z {}
contract A {
    function f() {
                                                       
    }
}
contract A {
    function f() {
                              
                               
    }
}
contract A {
    function f() {
                   
                                   
                         
    }
}
contract A {
    function f() {
                               
                                 
    }
}
contract A {
    function f() {
                   
                   
                                 
                               
    }
}
contract base {
  function fun() {
              
  }
}

contract derived is base() {
  function fun() {
              
  }
}

contract foo {
  function fun() {
  }
}

contract bar {
  function fun() {
  }
}

contract derived is foo, bar {
  function fun() {
  }
}
contract A {
    fixed40x40 storeMe;
    function f(ufixed x, fixed32x32 y) {
                    
                
    }
}
contract test {
  function fun(uint256 a) returns (address b) {
                                                                  
  }
}
contract test
{}

contract test {
  uint256 stateVar;
  function functionName(bytes20 arg1, address addr) constant
    returns (int id)
  { }
}
contract c {
    enum validEnum { Value1, Value2, Value3, Value4 }

    function c () {
                             
    }

    validEnum a;
}
contract c {
    event e();
}
contract c {
    event e() anonymous;
}
contract c {
    event e(uint a, bytes32 s);
}
contract c {
    event e(uint a, bytes32 indexed s, bool indexed b);
}
contract test {
    function fun(uint256 a) {
                           
    }
}
contract c {
    function x() external {}
}
contract c {
    function() { }
}
contract test {
    function fun(uint256 a) {
                      
                                  
                          
                  
                     
         
    }
}
contract test {
    function fun(uint256 a) {
                      
                  
                          
                  
                     
         
    }
}
contract test {
  function fun(uint256 a) {
                 
                            
                 
  }
}
contract test {
    function fun(uint256 a) {
                                          
                          
                  
                     
         
    }
}
contract test {
  function functionName(bytes32 input) returns (bytes32 out);
}
contract test {
    function fun(uint256 a) {
                     
                   
                
                      
         
    }
}

contract test {}

contract test {}

contract test {
  function fun() {
              
  }
}

contract test {}

contract c {
    uint[] a;
    function f() returns (uint, uint) {
                    
                                  
    }
}
contract test {
    function test() {
                  
                    
                     
                    
                   

                      
                      
                    
                   
                    
                    
    }

    uint256 a;
}

contract c {
    function c ()
    {
                                          
    }
    uint256 a;
}
contract Foo {
    function f() {
                         
                        
    }
}
contract test {
    mapping(address => bytes32) names;
}
contract test {
    struct test_struct {
        address addr;
        uint256 count;
        mapping(bytes32 => test_struct) self_reference;
    }
}
contract test {
    struct test_struct {
        address addr;
        mapping (uint64 => mapping (bytes32 => uint)) complex_mapping;
    }
}
contract c {
    modifier mod {                         }
}

contract c {
    modifier mod(address a) {                         }
}
contract c {
    modifier mod1(address a) {                         }
    modifier mod2 {                         }
    function f() mod1(7) mod2 { }
}
contract c {
    mapping(uint => mapping(uint => int8)[8][][9])[] x;
}
contract C {
    function f() {
                          
                    
                     
                     
                        
                        
                       
    }
    function g() returns (uint, uint, uint) {}
}
contract test {
  function fun() {
              
  }
}

contract test2 {
  function fun() {
              
  }
}

contract test {
  function fun() {
  }
}

contract test2 {
  function fun() {
  }
}

contract foo {
  function foo(uint a) {
  }
}

contract bar {
    function bar(string a, string b) {
    }
}

contract derived is foo(2), bar("abc", "def") {
  function fun() {
  }
}
contract test {
    function f() returns(bool succeeded) {
                     
    }
}
contract test {
  uint256 stateVar;
  function functionName() {}
}

contract test {
    function fun(int256 a) {
                                           
                                          
    }
}
contract test {
    function fun(uint a) returns(uint r) {           }
    function fun(uint a, uint b) returns(uint r) {               }
}
contract c {
    function fun() returns (uint r) {
                  
                     
    }
}

contract test {}
contract test {
  uint256 stateVar;
  function functionName(bytes32 input) returns (bytes32 out) {}
}
contract test {
  uint256 stateVariable1;
}
contract test {
    function fun() {
                  
    }
}
contract test {
    uint256 stateVar;
    struct MyStructName {
        address addr;
        uint256 count;
    }
}
contract C {
    function f() {
                     
                     
                               
                             
                
    }
}
contract test {
  function fun() {
                            
  }
}
contract test {
    function f() {
                     
            

               
                 

                       
    }
}

contract C {
    struct s { uint a; }
    using Lib for uint;
    using Lib for *;
    using Lib for s;

    function f() {
    }
}
contract test {
    function fun(uint256 a) {
                  
                  
                                    
    }
}
contract test {
    function fun(uint256 a) {
                  
                         
                         
                                    
                                  
    }
}
contract c {
    uint private a;
    uint internal b;
    uint public c;
    uint d;
    function f() {}
    function f_priv() private {}
    function f_public() public {}
    function f_internal() internal {}
}
contract test {
    function fun(uint256 a) {
                                                               
    }
}

contract test {
  function() {
            
                                                        
                         
                                           
                    
                                 
                               
                              
                  
                     
    
                           
                      
                                    
                      
                                
    
                           
                       
          
                                                    
                   
     
                                
    
   
  }
}

contract test {
  function f() view {
             
  }
  function g() pure {
             
  }
}

contract test {
  function f() {
                      
                       
  }
}

contract test {
  function f() {
              
               
              
            
  }
}

contract test {
  function foo() public returns (byte b) {
              
                    
     
  }
}

contract test {
    function() {
                                  
    }
}

contract test {
    constructor(uint a, uint b) withModifier {}
}

contract test {
    constructor(uint a, uint b) withModifier public {}
}

contract test {
  function () payable {
                                
  }
}

contract test {
  uint x = .1 ether;
}

contract test {
  function () {
                             
  }
}

contract test {
  uint x = 1000000;
  int x2 = -1000000;
  int x3 = -1000000 * 200;
  uint y = .25;
  uint y2 = 0.25;
  uint y3 = 10.25;
  uint y4 = 100.25;
  uint y5 = 0.0025 * 1e18;
  uint y6 = 1000000e-2;
  uint z = 0x11_22;
  uint z2 = 0x1122;
}

contract test {
  function _finalization() internal {
                        
                      
                                    
            
                              
     

                          
  }
}

contract test {
  function testFunction() {
            
                                             
                       
                              
                                 
                 
                                                              
                                   
                    
                                         
                   
             
         
     
   
  }
}

contract Sharer {
    function sendHalf(address payable addr) public payable returns (uint balance) {
                                                            
                                                           
                                     
                                                            
                                                                  
                                        
                                                                               
                                     
    }
}

contract FeedConsumer {
    DataFeed feed;
    uint errorCount;
    function rate(address token) public returns (uint value, bool success) {
                                                         
                               
                                 
                                                  
                             
                                                 
                                       
                                               
                                                
                         
                              
                                                 
                                                         
                                                         
                                            
                         
                              
                 
                                                              
                                                         
                                            
                         
                              
         
    }
}

contract test {
  receive () external payable {}
  fallback () external payable {}
}

contract D {
    uint public x;
    constructor(uint a) public payable {
              
    }
}

contract C {
    D d = new D(4); // will be executed as part of C's constructor

    function createD(uint arg) public {
                            
                 
    }

    function createAndEndowD(uint arg, uint amount) public payable {
                                             
                                           
                 
    }
}

contract D {
    uint public x;
    constructor(uint a) public {
              
    }
}

contract C {
    function createDSalted(bytes32 salt, uint arg) public {
                                                                      
                                                                   
                                                              
                                                                              
                       
                          
                 
                                       
                                     
                   
              
             

                                     
                                                
    }
}

contract owned {
    constructor() public {                     }
    address payable owner;
}

contract Destructible is owned {
    function destroy() virtual public {
                                                     
    }
}

contract Base1 is Destructible {
    function destroy() public virtual override {                                     }
}


contract Base2 is Destructible {
    function destroy() public virtual override {                                     }
}

contract Final is Base1, Base2 {
    function destroy() public override(Base1, Base2) {                  }
}

contract PayableAddress {
    function payableFn() public pure {
                  
                               
    }
}

contract VirtualA {
    GlobalBaseStruct base;
    event MyEvent(string _myString);
    function funA() public virtual {
                               
    }
}

contract VirtualB {
    function funA() public virtual {
                      
    }
}

contract VirtualOverdide is VirtualA, VirtualB {
    function funA() public override(VirtualB,VirtualA) {
                               
                     
    }
}

contract AssemblySlotNotation {
  function foo() {
              
                         
                        
     
  }
}

contract ArraySlices {
    function f(bytes calldata x) public {
                                                    
                                                
                                                  
    }
}

contract WithUncheckedBlock {
  function f() public pure returns (uint) {
               
                      
             
  }
}

contract stateVariables {
    bytes32 constant adminRole = keccak256("ADMIN_ROLE");
    uint immutable totalSupply;
    constructor(uint _totalSupply) public {
                                   
    }
}

contract userDefinedTypesAsMappingKeys {
  mapping (Foo => uint) map;
}

contract modifierWithVirtualOrOverride {
  modifier foo() virtual {  }
  modifier bar() override {  }
}

contract Base1
{
    function foo() virtual public {}
}

contract Base2
{
    function foo() virtual public {}
}

contract Inherited is Base1, Base2
{
    // Derives from multiple bases defining foo(), so we must explicitly
    // override it
    function foo() public override(Base1, Base2) {}
}

contract CallWithNameValue {
  function foo() {
                       
                                 
                                            
  }
}

contract FunctionsNamedAsKeywords {
  function receive() {}
  function leave() {}
}

contract ImmutableKeyword {
  uint immutable foo;
}

contract FallbackWithArgs {
  fallback (bytes calldata input) external payable returns (bytes memory output) {}
}

/*
 * Issues
 */

// issue #12
contract C {
  function f() public {
              
            
            
     
  }
}

// issue #54
contract Foo {
  function f() public {
                                                                     
                                                                       
                                                                       
                                                                         
  }
}

// issue #55
pragma solidity *;

// issue #59
contract C {
  using L.Lib for uint;
}

// issue #60
contract AssemblyAssingment {
    function foo() public pure {
                  
                                    
                      
                      
             

                    
                             
                         
         
    }
}

// issue #61
type Fixed18 is int256;
using Fixed18Lib for Fixed18 global;
using {plusOne, minusOne} for RestrictedNumber global;

contract Foo {
  function f() public {
                              
     
                                       
     
  }
}


contract GlobalVarName {
    function test() pure {
                           
    }
}

// solc 0.8.18, named parameters in mapping types
contract NamedMappingParams {
  mapping (address => bool) m1;
  mapping (address a => bool) m2;
  mapping (address => bool b) m3;
  mapping (address a => bool b) m4;
}

// solc 0.8.19, user defined operators
using { add as + } for Fixed18 global;
using { add as +, sub as - } for Fixed18 global;
