// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeContract.sol";

contract DateTimeHandler is BokkyPooBahsDateTimeContract {
    uint public immutable genesis_timestamp;
    uint public daysTill1st;
    

    struct Genesis_DateTime {
        uint year;
        uint month;
        uint day;
        uint hour;
        uint minute;
        uint second;
    }

    Genesis_DateTime[] public genesisDay;

    constructor() {
        genesis_timestamp = block.timestamp;
        (uint year, uint month, uint day, uint hour, uint minute, uint second) = timestampToDateTime(genesis_timestamp);
        Genesis_DateTime memory gdt = Genesis_DateTime(year,month,day,hour,minute,second);
        genesisDay.push(gdt);
        isValidDate(2022, 7, 1);
    }

    /// @notice takes genesis date and finds the next 1st of the month to assign payment dates to be uniform and calculated pro-rata
    function getNext1stFromGenesis() public returns (uint days_){
        Genesis_DateTime memory gdt = genesisDay[0];
        uint days_ = _daysFromDate(gdt.year, gdt.month + 1, 1);
        daysTill1st = days_;
        return days_;
    }

    function getNext1st1stFromGenesis() public returns (uint daysTill){
        Genesis_DateTime memory gdt = genesisDay[0];
        uint timestamp = timestampFromDate(gdt.year, gdt.month + 1, 1);
        (uint year, uint month, uint day) = timestampToDate(timestamp);
        uint daysTill = day;
        daysTill1st = daysTill;
        return daysTill;
    }

}

contract LandlordCompanion is DateTimeHandler, AccessControl {
    bytes32 public constant HANDLER_ROLE = keccak256("HANDLER_ROLE");

    address[] public paymentTokens;

    uint16 public landlordIds;
    uint16 public renterIds;
    uint16 public propertyIds;


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
        uint256 rentBalance; // how much rent is owed in arrears
        bytes identifier; // personal identifier
        bytes propIdentifer; // prop personal identifier
        uint16 internalId; // internal identifier
        bool isDeleted; // if true consider this renter to have been removed/deleted from the system
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

    mapping(address => bool) public paymentTypes; // address to is payment token true/false

    mapping(bytes => Landlord) public landlordsMap; // id to landlord
    mapping(bytes => Renter) public rentersMap; // id to renter
    mapping(bytes => Property) public propertiesMap; // OwnerId to property

    mapping(bytes => mapping(address => uint)) public paymentsMap; // paymentsMap[id][PaymentToken] = balance for that token
    mapping(address => uint) public renterRentOwedMap; // renterRentOwedMap[msg.sender]

    mapping(address => mapping(address => uint)) public landlordBalances; // 


    Landlord[] public landlords;
    Renter[] public renters;
    Property[] public Properties;

    event NewLandlord(address indexed wallet, bytes indexed identifier, uint16 indexed id);
    event LandlordRemoved(uint indexed id);
    event NewRenter(address indexed wallet, uint16 indexed propId, bytes indexed id);
    event RenterRemoved(uint indexed id);
    event NewProperty(bytes indexed identifier, bytes indexed owner, bytes indexed renter);
    event PropertyRemoved(bytes indexed identifier, bytes indexed owner);
    event RentChanged(bytes indexed propertyId, uint indexed usdMonthlyCost);
    event RentPaid(bytes indexed propertyId, uint indexed amount);

    error NotPropertyOwner(address caller, address owner);
    error NotAnAcceptedToken(address token, address[] acceptedTokens);

    constructor(address[] memory _tokens) DateTimeHandler(){
        _setupRole(HANDLER_ROLE, msg.sender);
        paymentTokens = _tokens;
        address z = _tokens[0];
        address zz = _tokens[1];
        landlordIds = 1;
        renterIds = 1;
        paymentTypes[z] = true;
        paymentTypes[zz] = true;
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

    function _addProp(bytes calldata _personalId, bytes calldata _ownerId, bytes calldata _renterId, uint _usdMonthly, address _renter, address _owner) public {
        uint large = _usdMonthly * 10 ** 18;
        
        Property memory pp = Property(propertyIds, _personalId, large, _renter, _owner, _ownerId, _renterId);
        propertyIds ++;

        Properties.push(pp);
        propertiesMap[_ownerId];
        emit NewProperty(_personalId, _ownerId, _renterId);

    }
    function addProps(Property[] calldata _props) public {
        for(uint x=0; x < _props.length; x++){
            _addProp(_props[x].identifier, _props[x].ownerId, _props[x].renterId, _props[x].usdMonthlyCost, _props[x].renter, _props[x].owner);
        }
    }

    function addPaymentToken(address _token) public {
        paymentTokens.push(_token);
        paymentTypes[_token] = true;
    }

    /// @param _wallet wallet to be paid into
    /// @param _propId how many properties
    /// @param _mrd monthly rent due from registered properties
    /// @param _id identifier

    /*
            address wallet; // payment wallet
        uint16 propertyID; // owner/rented property count
        uint256 monthlyRentDue; // how much rent due to be paid each month: rent = property.rent
        uint256 rentBalance; // how much rent is owed in arrears
        bytes identifier; // personal identifier
        bytes propIdentifer; // prop personal identifier
        uint16 internalId; // internal identifier
        bool isDeleted; // if true consider this renter to have been removed/deleted from the system
    */
        function addRenter(address _wallet, uint16 _propId, uint256 _rentBalance, uint256 _mrd, bytes calldata _id, bytes calldata _propIdentifier) external returns(Renter memory){
        require(_wallet != address(0)  && _propId > 0 && _mrd > 0 && _id.length > 0, "Paramater issue");
        uint16 id = renterIds;
        Renter memory rr = Renter(_wallet, _propId, _mrd,_rentBalance, _id, _propIdentifier, id, false);
        rentersMap[_id] = rr;
        renters.push(rr);
        renterIds ++;
        emit NewRenter(_wallet, _propId, _id);
        return rr;
    }

    /// @dev avoiding deleting from memory deciding to just blanket disable, internalId remains undeleted for internal accounting purposes
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

    /// @notice sets the property monthly rent as a solidity safe uint256
    /// @param _amount monthly usd cost of the property's rent
    /// @param _id bytes identifier of the property
    /// @notice modifier vs if() revert NotPropertyOwner()
    function setProperyRent(uint _amount, bytes calldata _id) public {
        Property storage pp = propertiesMap[_id];
        if(msg.sender != pp.owner) revert NotPropertyOwner({caller: msg.sender, owner: pp.owner});
        pp.usdMonthlyCost = _amount;
        emit RentChanged(_id, pp.usdMonthlyCost);
    }

    /// @notice allows a renter to choose a payment token pass an amount and their own bytes id to pay rent
    /// @dev reverts if _token isn't in paymentTypes[]
    /// @param _token the payment token
    /// @param _amount how much to pay
    /// @param _id renter personal bytes id
    function payRent(address _token, uint _amount, bytes calldata _id) public {
        if(paymentTypes[_token] == false) revert NotAnAcceptedToken(_token, paymentTokens);
        Renter storage rr = rentersMap[_id];
        Landlord storage ll = landlordsMap[rr.propIdentifer];
        rr.rentBalance -= _amount;
        landlordBalances[ll.wallet][_token] += _amount;
        IERC20(_token).transferFrom(msg.sender, ll.wallet, _amount);
    }


    /// @notice withdraws all balances for the landlord from the landlordBalances mapping
    /// @param _id personal bytes identifier of the landlord
    /// @dev withdraws whole balance and sends via the registered landlord wallet not the msg.sender so anyone can call right now
    function landlordWithdrawAll(bytes calldata _id) public {
        Landlord memory ll = landlordsMap[_id];
        if(msg.sender != ll.wallet) revert NotPropertyOwner({caller: msg.sender, owner: ll.wallet});
        address[] memory tokens;
        for(uint x=0;x<paymentTokens.length; x++){
            address token = tokens[x];
            uint bal = landlordBalances[ll.wallet][token];
            IERC20(token).transfer(ll.wallet, bal);
        }
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
    
    function getRenter(bytes memory _id) public view returns(address wallet_, uint16 propId_, uint256 mrd_, bytes memory identifier_, uint16 internalId_, bool isDeleted_){
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

    function getProperty(bytes memory _id) public view returns(uint16 internalId, bytes memory identifier, uint usdMonthlyCost, address renter, address owner, bytes memory ownerId, bytes memory renterId) {
        Property memory pp = propertiesMap[_id];
        (internalId, identifier, usdMonthlyCost, renter, owner, ownerId, renterId) = returnProperty(pp);
        return (internalId, identifier, usdMonthlyCost, renter, owner, ownerId, renterId);
    }

    function returnProperty(Property memory _pp) public pure returns(uint16 internalId_, bytes memory identifier_, uint usdMonthlyCost_, address renter_, address owner_, bytes memory ownerId_, bytes memory renterId_) {
        internalId_ = _pp.internalId;
        identifier_ = _pp.identifier;
        usdMonthlyCost_ = _pp.usdMonthlyCost;
        renter_ = _pp.renter;
        owner_ = _pp.owner;
        ownerId_ = _pp.ownerId;
        renterId_ = _pp.renterId;
        return (internalId_, identifier_, usdMonthlyCost_, renter_, owner_, ownerId_, renterId_);
    }

}
