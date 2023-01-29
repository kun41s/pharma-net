// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

contract Pharma {

    enum Roles {
        Manufacturer, Distributor, Retailer, Transporter, Consumer
    }

    struct Company {
        uint256 CRN;
        address owner;
        string name;
        string location;
        Roles role;
    }

    struct Drug {
        bytes32 id;
        string name;
        uint256 serialNo;
        address manufacturer;
        uint256 mfgDate;
        uint256 expDate;
        Roles currentOwner;
        string shipment;
    }

    struct PurchaseOrder {
        bytes32 id;
        string drugName;
        uint256 quantity;
        uint256 buyerCRN;
        uint256 sellerCRN;
    }

    Roles role;

    modifier onlyCompany(address _owner) {
        require(_owner == companies[msg.sender].owner, "Company must be registered");
        _;
    }

    mapping (address => Company) companies;
    mapping (address => Drug[]) public drugs;
    // mapping (address => PurchaseOrder[]) shipmentOrders;
    mapping (address => PurchaseOrder) purchaseOrders;

    // "123", "abc", "la", 0
    function registerCompany(uint256 _crn, string memory _name, string memory _location, Roles _role) public returns (bool) {
        require(msg.sender != companies[msg.sender].owner, "address is already owning a company");
        // myCompany.role = _role;
        companies[msg.sender] = Company(_crn, msg.sender, _name, _location, _role);
        return true;   
    }

    // 123, abc, 009, 0987, 1234, 123, 0
    function addDrug(string memory _name, uint256 _serialNo, uint256 _mfgDate, uint256 _expDate, uint256 _companyCRN, Roles _currentOwner) public onlyCompany(msg.sender) returns (bool) {
        require(_companyCRN == companies[msg.sender].CRN, "Company Not Registered");
        require(_currentOwner == companies[msg.sender].role, "You must be manufacturer");

        bytes32 drugId = bytes32(sha256(abi.encodePacked(_name, _serialNo))); 

        drugs[msg.sender].push(Drug(drugId, _name, _serialNo, msg.sender, _mfgDate, _expDate, _currentOwner, ""));
        return true;
    }

    function getDrugs() public view returns(Drug[] memory) {
        return drugs[msg.sender];
    }

    function createPO( uint256 _sellerCRN, string memory _drugName, uint256 _quantity) public onlyCompany(msg.sender) returns (bool) {
        uint256 buyerCRN = companies[msg.sender].CRN;
        bytes32 id = sha256(abi.encodePacked(buyerCRN, _drugName));
        require(buyerCRN != _sellerCRN, "Seller can't create order");
        require (companies[msg.sender].role != Roles(0), "Manufacturer cannot create purchase order");

        // shipmentOrders[]
        // purchaseOrders[msg.sender].push(PurchaseOrder(id, _drugName, _quantity, buyerCRN, _sellerCRN));
        purchaseOrders[msg.sender] = PurchaseOrder(id, _drugName, _quantity, buyerCRN, _sellerCRN);
        return true;
    }

    function createShipment(uint256 _buyerCRN, string memory _drugName, uint256 _listOfAssets, uint256 _transporterCRN) public onlyCompany(msg.sender) returns (bool) {
        require(companies[msg.sender].role == Roles(0), "only manufacturer can create shipment order");
        require(purchaseOrders[msg.sender].sellerCRN == companies[msg.sender].CRN, "You do not have any purchase order");
        return true;
    }
}