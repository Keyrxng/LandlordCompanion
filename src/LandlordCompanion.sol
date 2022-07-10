// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract LandlordCompanion is AccessControl {
    bytes32 public constant HANDLER_ROLE = keccak256("HANDLER_ROLE");

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


    constructor() {
        _setupRole(HANDLER_ROLE, msg.sender);
    }

    /// @param _wallet wallet to be paid into
    /// @param _payments accepted payment tokens
    /// @param _propCount how many properties
    /// @param _mrd monthly rent due from registered properties
    /// @param _id identifier
    function addLandlord(address _wallet, address[] calldata _payments, uint16 _propCount, uint256 _mrd, bytes calldata _id) external {
        Landlord memory ll = Landlord(_wallet, _payments, _propCount, _mrd, _id);
        landlordsMap[_id] = ll;
        landlords.push(ll);
    }

    /// @param _wallet wallet to be paid into
    /// @param _propId how many properties
    /// @param _mrd monthly rent due from registered properties
    /// @param _id identifier
        function addRenter(address _wallet, uint16 _propId, uint256 _mrd, bytes calldata _id) external {
        Renter memory rr = Renter(_wallet, _propId, _mrd, _id);
        rentersMap[_id] = rr;
        renters.push(rr);
    }



}
