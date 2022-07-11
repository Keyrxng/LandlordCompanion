// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/solmate/src/tokens/ERC20.sol";
import "../src/LandlordCompanion.sol";

contract LandlordCompanionTest is Test {

    LandlordCompanion companion;
    address[] paymentTokens = [0xbFC15E1294d1975DDB3698E5Fc5bC14DD4680f83, 0xbFC15E1294d1975DDB3698E5Fc5bC14DD4680f83];
    
    
    function setUp() public {
        companion = new LandlordCompanion(paymentTokens);        
    }


    function testAddLandlord() public {
        vm.expectEmit(true,false,false,true);
        companion.addLandlord(msg.sender, paymentTokens, 1, 500, bytes(string("my duuuude")));
        companion.addLandlord(msg.sender, paymentTokens, 1, 500, bytes(string("my duuuude")));
        
    }

    function testAddRenter() public {
        vm.expectEmit(true,false,false,true);
        companion.addRenter(msg.sender, 1, 500, bytes(string("my duuuude")));
        companion.addRenter(msg.sender, 1, 500, bytes(string("my duuuude")));

    }
}
