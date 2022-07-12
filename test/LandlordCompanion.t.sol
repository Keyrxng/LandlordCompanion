// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/LandlordCompanion.sol";
import "../src/MockERC.sol";

contract LandlordCompanionTest is Test {    

    LandlordCompanion public companion;
    address[] public paymentTokens = [0xbFC15E1294d1975DDB3698E5Fc5bC14DD4680f83, 0xbFC15E1294d1975DDB3698E5Fc5bC14DD4680f83];
    address owner = 0xd48cbCB461144E2aF0a726e9909ab86029B39d50;
    address renter = 0x14FcCaBE00F2354011b2a0EBedD845D40C0c7a15; 
        
    uint16 landlordIds;
    uint16 renterIds;

    MockERC public mockToken;

    bytes public constant PERSON0 = bytes(string("Owner"));
    bytes public constant PERSON1 = bytes(string("Renter"));

    bytes public constant ENTITY0 = bytes(string("Property0"));
    bytes public constant ENTITY1 = bytes(string("Property1"));


    // event NewLandlord(address indexed wallet, bytes indexed identifier, uint16 indexed id);
    // event LandlordRemoved(uint indexed id);
    // event NewRenter(address indexed wallet, uint16 indexed propId, bytes indexed id);
    // event RenterRemoved(uint indexed id);

    event NewLandlord(address indexed wallet, bytes indexed identifier, uint16 indexed id);
    event LandlordRemoved(uint indexed id);
    event NewRenter(address indexed wallet, uint16 indexed propId, bytes indexed id);
    event RenterRemoved(uint indexed id);
    event NewProperty(bytes indexed identifier, bytes indexed owner, bytes indexed renter);
    event PropertyRemoved(bytes indexed identifier, bytes indexed owner);
    event RentChanged(bytes indexed propertyId, uint indexed usdMonthlyCost);
    event RentPaid(bytes indexed propertyId, uint indexed amount);

    error NotPropertyOwner(address caller, address owner);
    error NotAnAcceptedToken(address token);

    struct Landlord {
        address wallet; // payment wallet
        address[] paymentTokens; // accepted payment tokens
        uint16 propertyCount; // owned/registered property counter
        uint256 monthlyRentDue; // how much rent due each month: rent = property[x].rent
        bytes identifier; // personal identifier
        uint16 internalId; // internal identifier
        bool isDeleted; // if true consider this landlord to have been removed/deleted from the system
    }

    struct Property {
        uint16 internalId; // internal accounting
        bytes identifier; // personal id
        uint usdMonthlyCost;
        address renter;
        address owner;
        bytes ownerId; // ownerId
        bytes renterId; // renterId
    }

    function setUp() public {
        companion = new LandlordCompanion(paymentTokens);   
        landlordIds = 1;
        renterIds = 1;
        mockToken = new MockERC(renter);
        companion.addPaymentToken(address(mockToken));

    }


    function testAddLandlord() public {
        vm.expectEmit(true,true,true,true);
        emit NewLandlord(msg.sender, PERSON0, landlordIds);
        companion.addLandlord(msg.sender, paymentTokens, 1, 500, PERSON0);
        
    }
    function testAddProps() public {
        // (bytes memory personalId, uint cost, address renter, ,address owner, bytes memory ownerId, bytes memory renterId);
        vm.expectEmit(true, true, true, true);
        emit NewProperty(ENTITY0, PERSON0, PERSON1);
        // Property memory pp = Property({internalId: 1, identifier: ENTITY0, usdMonthlyCost: 450 * 10 ** 18, renter: renter, owner: owner, ownerId: PERSON0, renterId: PERSON1});
        companion._addProp({_personalId: ENTITY0, _usdMonthly: 450 * 10 ** 18, _renter: renter, _owner: owner, _ownerId: PERSON0, _renterId: PERSON1});
        // returnProperty(ENTITY0);
            //renter priv key f643a74d9544061306904a4ced4ac17365ca6c7dcefe3d96fa9db7bd0343910d
            // renter pub key 0x14FcCaBE00F2354011b2a0EBedD845D40C0c7a15
            // owner priv key b43b6c1dc5d3a06ccfee9155e3679aea276103be0dbd38b702e2e805d901516c
            // owner pub key 0xd48cbCB461144E2aF0a726e9909ab86029B39d50
    }

    function testChangeRent() public {
        hoax(0xd48cbCB461144E2aF0a726e9909ab86029B39d50);
        vm.expectEmit(true, true, false, true);
        emit RentChanged(ENTITY0, 500 * 10 ** 18);
        companion.setProperyRent(500 * 10 ** 18, ENTITY0);
    }

    function testPayRent() public {
        vm.expectEmit(true,true,true,true);
        emit RentPaid(ENTITY0, 500 * 10 ** 18);
        companion.payRent(address(mockToken), 500 * 10 ** 18, PERSON1);
    }

    function testAddRenter() public {
        vm.expectEmit(true,true,true,true);
        emit NewRenter(msg.sender, 1, PERSON1);
        companion.addRenter(msg.sender, 1, 450 * 10 ** 18, 450 * 10 ** 18, PERSON1, ENTITY0);
    }

    function testRemoveLandlord() public {
        vm.expectEmit(true,true,true,true);
        emit NewLandlord(msg.sender, PERSON0, landlordIds);
        companion.addLandlord(msg.sender, paymentTokens, 1, 450 * 10 ** 18, PERSON0);

        // (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = returnLandlord();
        // bool res = isDeleted_;
        // assertFalse(res);

        vm.expectEmit(true,false,false,true);
        emit LandlordRemoved(landlordIds);
        companion.removeLandlord(PERSON0);
        (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getLandlord(PERSON0);
        bool res = isDeleted_;
        assertTrue(res);

    }
    function testRemoveRenter() public {
        vm.expectEmit(true,true,true,true);
        emit NewRenter(msg.sender, 1, PERSON1);
        companion.addRenter(msg.sender, 1, 450 * 10 ** 18, 450 * 10 ** 18, PERSON1, ENTITY0);

        vm.expectEmit(true,false,false,true);
        emit RenterRemoved(renterIds);
        companion.removeRenter(PERSON1);
        (address wallet_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getRenter(PERSON1);
        bool res = isDeleted_;
        assertTrue(res);
    }

    function testFailRemoveLandlord() public {
        vm.expectEmit(true,true,true,true);
        emit NewLandlord(msg.sender, PERSON0, landlordIds);
        companion.addLandlord(msg.sender, paymentTokens, 1, 450 * 10 ** 18, PERSON0);

        vm.expectEmit(true,false,false,true);
        emit LandlordRemoved(landlordIds);
        companion.removeLandlord(PERSON0);
        (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getLandlord(PERSON0);
        bool res = isDeleted_;
        assertFalse(res);

    }
    function testFailRemoveRenter() public {
        vm.expectEmit(true,true,true,true);
        emit NewRenter(msg.sender, 1, PERSON1);
        companion.addRenter(msg.sender, 1, 450 * 10 ** 18, 450 * 10 ** 18, PERSON1, ENTITY0);

        vm.expectEmit(true,false,false,true);
        emit RenterRemoved(renterIds);
        companion.removeRenter(PERSON1);
        (address wallet_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getRenter(PERSON1);
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

    function returnLandlord(bytes memory _id) public view returns (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) {
        (address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getLandlord(_id);
        return (wallet_, paymentTokens_, propCount_, mrd_, identifier_, internalId_, isDeleted_);
    }
    function returnRenter(bytes memory _id) public view returns (address wallet_, uint16 propId_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) {
        (address wallet_, uint16 propId_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) = companion.getRenter(_id);
        return (wallet_, propId_, mrd_, identifier_, internalId_, isDeleted_);
    }

    function returnProperty(bytes memory _id) public view returns(uint16 internalId_, bytes memory personalId_,uint cost_, address renter_, address owner_,bytes memory ownerId_, bytes memory renterId_) {
        (uint16 internalId_, bytes memory personalId_, uint cost_, address renter_, address owner_, bytes memory ownerId_, bytes memory renterId_) = companion.getProperty(_id);
        return (internalId_, personalId_, cost_, renter_, owner_, ownerId_, renterId_);
    }

}
