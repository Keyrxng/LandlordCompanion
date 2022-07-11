// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract LandlordCompanion is AccessControl {
    bytes32 public constant HANDLER_ROLE = keccak256("HANDLER_ROLE");

    address[] public paymentTokens;

    uint16 public landlordIds;
    uint16 public renterIds;

    struct Landlord {
        address wallet; // payment wallet
        address[] paymentTokens; // accepted payment tokens
        uint16 propertyCount; // owned/registered property counter
        uint256 monthlyRentDue; // how much rent due each month: rent = property[x].rent
        bytes identifier; // personal identifier
        uint16 internalId; // internal identifier
        bool isDeleted; // if true consider this landlord to have been removed/deleted from the system
    }

    struct Renter {
        address wallet; // payment wallet
        uint16 propertyID; // owner/rented property count
        uint256 monthlyRentDue; // how much rent due to be paid each month: rent = property.rent
        bytes identifier; // personal identifier
        uint16 internalId; // internal identifier
        bool isDeleted; // if true consider this renter to have been removed/deleted from the system
    }

    mapping(bytes => Landlord) public landlordsMap; // id to landlord
    mapping(bytes => Renter) public rentersMap; // id to landlord

    mapping(bytes => mapping(address => uint)) public paymentsMap; // paymentsMap[id][PaymentToken] = balance for that token
    mapping(address => mapping(uint => Renter)) public renterRentOwedMap;



    Landlord[] public landlords;
    Renter[] public renters;

    event NewLandlord(address indexed wallet, bytes indexed identifier, uint16 indexed id);
    event LandlordRemoved(uint indexed id);
    event NewRenter(address indexed wallet, uint16 indexed propId, bytes indexed id);
    event RenterRemoved(uint indexed id);

    constructor(address[] memory _tokens) {
        _setupRole(HANDLER_ROLE, msg.sender);
        paymentTokens = _tokens;
        landlordIds = 1;
        renterIds = 1;
    }

    /// @param _wallet wallet to be paid into
    /// @param _payments accepted payment tokens
    /// @param _propCount how many properties
    /// @param _mrd monthly rent due from registered properties
    /// @param _id identifier
    function addLandlord(address _wallet, address[] calldata _payments, uint16 _propCount, uint256 _mrd, bytes calldata _id) external returns(Landlord memory){
        require(_wallet != address(0) && _payments.length > 0 && _propCount > 0 && _mrd > 0 && _id.length > 0, "Paramater issue");
        uint16 id = landlordIds;
        Landlord memory ll = Landlord(_wallet, _payments, _propCount, _mrd, _id, id, false);
        landlordsMap[_id] = ll;
        landlords.push(ll);
        landlordIds ++;
        emit NewLandlord(_wallet, _id, id);
        return ll;
    }

    /// @param _wallet wallet to be paid into
    /// @param _propId how many properties
    /// @param _mrd monthly rent due from registered properties
    /// @param _id identifier
        function addRenter(address _wallet, uint16 _propId, uint256 _mrd, bytes calldata _id) external returns(Renter memory){
        require(_wallet != address(0)  && _propId > 0 && _mrd > 0 && _id.length > 0, "Paramater issue");
        uint16 id = renterIds;
        Renter memory rr = Renter(_wallet, _propId, _mrd, _id, id, false);
        rentersMap[_id] = rr;
        renters.push(rr);
        renterIds ++;
        emit NewRenter(_wallet, _propId, _id);
        return rr;
    }

    /// @dev avoiding deleting from storage deciding to just blanket disable, internalId remains undeleted for internal accounting purposes
    /// @param _id the byte represenation of the landlord's personal identifier
    function removeLandlord(bytes calldata _id) public {
        Landlord storage ll = landlordsMap[_id];
        ll.isDeleted = true;
        delete ll.wallet;
        delete ll.paymentTokens;
        delete ll.propertyCount;
        delete ll.monthlyRentDue;
        delete ll.identifier;
        emit LandlordRemoved(ll.internalId);
    }

    /// @dev avoiding deleting from storage deciding to just blanket disable, internalId remains undeleted for internal accounting purposes
    /// @param _id the byte represenation of the renter's personal identifier
    function removeRenter(bytes calldata _id) public {
        Renter storage rr = rentersMap[_id];
        rr.isDeleted = true;
        delete rr.wallet;
        delete rr.propertyID;
        delete rr.monthlyRentDue;
        delete rr.identifier;
        emit RenterRemoved(rr.internalId);
    }


    













    function getLandlord(bytes calldata _id) public view returns(address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_){
        Landlord memory ll = landlordsMap[_id];
        (wallet_, paymentTokens_, propCount_, mrd_, identifier_, internalId_, isDeleted_) = returnLandlord(ll);
        return (wallet_, paymentTokens_, propCount_, mrd_, identifier_, internalId_, isDeleted_);
    }

    function returnLandlord(Landlord memory _ll) public pure returns(address wallet_, address[] memory paymentTokens_, uint16 propCount_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) {
        wallet_ = _ll.wallet;
        paymentTokens_ = _ll.paymentTokens;
        propCount_ = _ll.propertyCount;
        mrd_ = _ll.monthlyRentDue;
        identifier_ = _ll.identifier;
        internalId_ = _ll.internalId;
        isDeleted_ = _ll.isDeleted;
        return (wallet_, paymentTokens_, propCount_, mrd_, identifier_, internalId_, isDeleted_);
    }
    
    function getRenter(bytes calldata _id) public view returns(address wallet_, uint16 propId_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_){
        Renter memory rr = rentersMap[_id];
        (wallet_, propId_, mrd_, identifier_, internalId_, isDeleted_) = returnRenter(rr);
        return (wallet_, propId_, mrd_, identifier_, internalId_, isDeleted_);
    }

    function returnRenter(Renter memory _rr) public pure returns(address wallet_, uint16 propId_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_) {
        wallet_ = _rr.wallet;
        propId_ = _rr.propertyID;
        mrd_ = _rr.monthlyRentDue;
        identifier_ = _rr.identifier;
        internalId_ = _rr.internalId;
        isDeleted_ = _rr.isDeleted;
        return (wallet_, propId_, mrd_, identifier_, internalId_, isDeleted_);
    }



}
