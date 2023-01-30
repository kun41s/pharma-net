// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

contract Pharma {

    enum Roles {
        Manufacturer, Distributor, Retailer, Transporter, Consumer
    }

    enum Status {
        inTransit, delivered
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

    struct ListOfAssets {
        bytes32 id;
        string drugName;
        uint256 quantity;
    }

    struct Shipment {
        bytes32 id;
        uint256 creator;
        string drugName;
        uint256 quantity;  // ListOfAssets
        uint256 transporter;
        Status status;
    }

    modifier onlyCompany(address _owner) {
        require(_owner == companies[msg.sender].owner, "Company must be registered");
        _;
    }

    Roles role;
    mapping (address => Company) companies;
    mapping (address => Drug[]) public drugs;
    // mapping (address => PurchaseOrder[]) shipmentOrders;
    mapping (uint256 => PurchaseOrder) purchaseOrders;
    mapping (uint256 => Shipment) public shipments;

    // "123", "abc", "la", 0
    // 12345, abcde, la, 1
    // 123456, trans, la, 3
    function registerCompany(uint256 _crn, string memory _name, string memory _location, Roles _role) public returns (bool) {
        require(msg.sender != companies[msg.sender].owner, "address is already owning a company");
        // myCompany.role = _role;
        companies[msg.sender] = Company(_crn, msg.sender, _name, _location, _role);
        return true;   
    }

    // abc, 1234, 009, 0987, 123, 0
    function addDrug(string memory _name, uint256 _serialNo, uint256 _mfgDate, uint256 _expDate, uint256 _companyCRN, Roles _currentOwner) public onlyCompany(msg.sender) returns (bool) {
        require(_companyCRN == companies[msg.sender].CRN, "Company Not Registered");
        require(_currentOwner == companies[msg.sender].role, "You must be manufacturer");

        bytes32 drugId = bytes32(sha256(abi.encodePacked(_name, _serialNo))); 

        drugs[msg.sender].push(Drug(drugId, _name, _serialNo, msg.sender, _mfgDate, _expDate, Roles(0), ""));
        return true;
    }

    function getDrugs() public view returns(Drug[] memory) {
        return drugs[msg.sender];
    }

    // 123, abc, 20
    function createPO( uint256 _sellerCRN, string memory _drugName, uint256 _quantity) public onlyCompany(msg.sender) returns (bool) {
        uint256 buyerCRN = companies[msg.sender].CRN;
        bytes32 id = sha256(abi.encodePacked(buyerCRN, _drugName));
        require(buyerCRN != _sellerCRN, "Manufacturer can't create order");
        require (companies[msg.sender].role != Roles(0), "Manufacturer cannot create purchase order");

        // shipmentOrders[]
        // purchaseOrders[msg.sender].push(PurchaseOrder(id, _drugName, _quantity, buyerCRN, _sellerCRN));
        purchaseOrders[buyerCRN] = PurchaseOrder(id, _drugName, _quantity, buyerCRN, _sellerCRN);
        return true;
    }

    // 12345, abc, 
    function createShipment(uint256 _buyerCRN, string memory _drugName, uint256 _quantity, uint256 _transporterCRN) public onlyCompany(msg.sender) returns (bool) {
        require(companies[msg.sender].role == Roles(0), "only manufacturer can create shipment order");
        // require(purchaseOrders[msg.sender].sellerCRN == companies[msg.sender].CRN, "You do not have any purchase order");
        uint256 sellerCRN = companies[msg.sender].CRN;
        require (purchaseOrders[_buyerCRN].sellerCRN == sellerCRN, "Order Not Found");
        // string memory transporterName = companies[]
        bytes32 id = sha256(abi.encodePacked(_buyerCRN, _drugName));
        // bytes32 transporter = sha256(abi.encodePacked(_transporterCRN));    // Add transporter name;
        shipments[_transporterCRN] = Shipment(id, companies[msg.sender].CRN, "abc", _quantity, _transporterCRN, Status(0));
        return true;
    }

    function updateShipment(uint256 _buyerCRN, string memory _drugName) public returns (bool) {
        uint256 transporterCRN = companies[msg.sender].CRN;
        require(companies[msg.sender].CRN != _buyerCRN, "Manufacturer can't be buyer or transporter");
        require(companies[msg.sender].CRN == transporterCRN, "Transporter Not Found");
        if(shipments[transporterCRN].transporter == transporterCRN) {
            if (sha256(abi.encodePacked(shipments[transporterCRN].drugName)) == sha256(abi.encodePacked(_drugName))) {
                shipments[transporterCRN].status = Status(1);
                return true;
            }
        } else {
            return false;
        }
        return true;
        // shipments[msg.sender] = Shipment
    }

    function getShipments() public view returns(Shipment memory) {
        uint256 myCRN = companies[msg.sender].CRN;
        return shipments[myCRN];
    }
}