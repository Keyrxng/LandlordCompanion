// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract LandlordCompanion is AccessControl {
    bytes32 public constant HANDLER_ROLE = keccak256("HANDLER_ROLE");

    address[] paymentTokens;

    struct Landlord {
        address wallet; // payment wallet
        address[] paymentTokens; // accepted payment tokens
        uint16 propertyCount; // owned/registered property counter
        uint256 monthlyRentDue; // how much rent due each month: rent = property[x].rent
        bytes identifier;
    }

    struct Renter {
        address wallet; // payment wallet
        uint16 propertyID; // owner/rented property count
        uint256 monthlyRentDue; // how much rent due to be paid each month: rent = property.rent
        bytes identifier; 
    }

    mapping(bytes => Landlord) public landlordsMap; // id to landlord
    mapping(bytes => Renter) public rentersMap; // id to landlord

    Landlord[] public landlords;
    Renter[] public renters;

    event NewLandlord(address indexed wallet, bytes indexed id);
    event NewRenter(address indexed wallet, uint16 propId, bytes id);


    constructor(address[] memory _tokens) {
        _setupRole(HANDLER_ROLE, msg.sender);
        paymentTokens = _tokens;
    }

    /// @param _wallet wallet to be paid into
    /// @param _payments accepted payment tokens
    /// @param _propCount how many properties
    /// @param _mrd monthly rent due from registered properties
    /// @param _id identifier
    function addLandlord(address _wallet, address[] calldata _payments, uint16 _propCount, uint256 _mrd, bytes calldata _id) external {
        require(_wallet != address(0) && _payments.length > 0 && _propCount > 0 && _mrd > 0 && _id.length > 0, "Paramater issue");
        Landlord memory ll = Landlord(_wallet, _payments, _propCount, _mrd, _id);
        landlordsMap[_id] = ll;
        landlords.push(ll);
        emit NewLandlord(_wallet, _id);
    }

    /// @param _wallet wallet to be paid into
    /// @param _propId how many properties
    /// @param _mrd monthly rent due from registered properties
    /// @param _id identifier
        function addRenter(address _wallet, uint16 _propId, uint256 _mrd, bytes calldata _id) external {
        require(_wallet != address(0)  && _propId > 0 && _mrd > 0 && _id.length > 0, "Paramater issue");
        Renter memory rr = Renter(_wallet, _propId, _mrd, _id);
        rentersMap[_id] = rr;
        renters.push(rr);
        emit NewRenter(_wallet, _propId, _id);
    }



}
