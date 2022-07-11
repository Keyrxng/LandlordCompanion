// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/solmate/src/tokens/ERC20.sol";
import "../src/LandlordCompanion.sol";

contract LandlordCompanionTest is Test {
    

    LandlordCompanion companion;
    address[] paymentTokens = [0xbFC15E1294d1975DDB3698E5Fc5bC14DD4680f83, 0xbFC15E1294d1975DDB3698E5Fc5bC14DD4680f83];
    
    uint16 landlordIds;
    uint16 renterIds;

    event NewLandlord(address indexed wallet, bytes indexed identifier, uint16 indexed id);
    event LandlordRemoved(uint indexed id);
    event NewRenter(address indexed wallet, uint16 indexed propId, bytes indexed id);
    event RenterRemoved(uint indexed id);

    struct Landlord {
        address wallet; // payment wallet
        address[] paymentTokens; // accepted payment tokens
        uint16 propertyCount; // owned/registered property counter
        uint256 monthlyRentDue; // how much rent due each month: rent = property[x].rent
        bytes identifier; // personal identifier
        uint16 internalId; // internal identifier
        bool isDeleted; // if true consider this landlord to have been removed/deleted from the system
    }
    function setUp() public {
        companion = new LandlordCompanion(paymentTokens);   
        landlordIds = 1;
        renterIds = 1;     
    }


    function testAddLandlord() public {
        vm.expectEmit(true,true,true,true);
        emit NewLandlord(msg.sender, bytes(string("my duuuude")), landlordIds);
        companion.addLandlord(msg.sender, paymentTokens, 1, 500, bytes(string("my duuuude")));
        
    }

    function testAddRenter() public {
        vm.expectEmit(true,true,true,true);
        emit NewRenter(msg.sender, 1, bytes(string("this guy")));
        companion.addRenter(msg.sender, 1, 500, bytes(string("this guy")));
    }
        bytes name = bytes(string("my duuuude"));

    function testRemoveLandlord() public {
        vm.expectEmit(true,true,true,true);
        emit NewLandlord(msg.sender, name, landlordIds);
        companion.addLandlord(msg.sender, paymentTokens, 1, 500, name);

        // (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = returnLandlord();
        // bool res = isDeleted_;
        // assertFalse(res);

        vm.expectEmit(true,false,false,true);
        emit LandlordRemoved(landlordIds);
        companion.removeLandlord(name);
        (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getLandlord(name);
        bool res = isDeleted_;
        assertTrue(res);

    }
    function testRemoveRenter() public {
        vm.expectEmit(true,true,true,true);
        emit NewRenter(msg.sender, 1, name);
        companion.addRenter(msg.sender, 1, 500, name);

        vm.expectEmit(true,false,false,true);
        emit RenterRemoved(renterIds);
        companion.removeRenter(name);
        (address wallet_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getRenter(name);
        bool res = isDeleted_;
        assertTrue(res);
    }

        function testFailRemoveLandlord() public {
        vm.expectEmit(true,true,true,true);
        emit NewLandlord(msg.sender, name, landlordIds);
        companion.addLandlord(msg.sender, paymentTokens, 1, 500, name);

        vm.expectEmit(true,false,false,true);
        emit LandlordRemoved(landlordIds);
        companion.removeLandlord(name);
        (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getLandlord(name);
        bool res = isDeleted_;
        assertFalse(res);

    }
    function testFailRemoveRenter() public {
        vm.expectEmit(true,true,true,true);
        emit NewRenter(msg.sender, 1, name);
        companion.addRenter(msg.sender, 1, 500, name);

        vm.expectEmit(true,false,false,true);
        emit RenterRemoved(renterIds);
        companion.removeRenter(name);
        (address wallet_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getRenter(name);
        bool res = isDeleted_;
        assertFalse(res);
    }

    function testDateTimeFind1st1st() public {
        uint _days = companion.getNext1stFromGenesis();
        emit log_uint(_days);
    }
        function testDateTimeFind1st() public {
        uint _days = companion.getNext1st1stFromGenesis();
        emit log_uint(_days);
    }

    function testAddProps() public {
        let propDetails = (bytes presonalId, bytes ownerId, uint cost, address renter, address owner);
         = companion.addProps();
    }

    function returnLandlord() public view returns (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) {
        (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getLandlord(name);
        return (wallet_, paymentTokens_, propCount_, mrd_, identifier_, internalId_, isDeleted_);
    }
    function returnRenter() public view returns (address wallet_, uint16 propId_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) {
        (address wallet_, uint16 propId_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getRenter(name);
        return (wallet_, propId_, mrd_, identifier_, internalId_, isDeleted_);
    }

    function returnProperty() public view returns(bytes memory presonalId, bytes memory ownerId, uint cost, address renter, address owner) {
        (bytes memory presonalId, bytes memory ownerId, uint cost, address renter, address owner) = companion.getProperty();w
    }

}
