// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

contract Pharma {
    enum Roles {
        Manufacturer,
        Distributor,
        Retailer,
        Transporter
    }

    enum Status {
        inTransit,
        delivered
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
        uint256 manufacturer;
        uint256 mfgDate;
        uint256 expDate;
        uint256 currentOwner;
        uint256 shipment;
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
        uint256 serialNo;
        uint256 quantity;
        uint256 transporter;
        Status status;
    }

    struct Ownership {
        string drugName;
        uint256 serialNo;
        uint256 from;
        uint256 to;
    }

    modifier onlyCompany(address _owner) {
        require(
            _owner == companies[msg.sender].owner,
            "Company must be registered"
        );
        _;
    }

    event OwnerChange(
        string drugName,
        uint256 serialNo,
        uint256 from,
        uint256 to
    );
    mapping(address => Company) companies;
    mapping(string => mapping(uint256 => Drug)) drugs;
    mapping(string => mapping(uint256 => Ownership[])) ownerships;
    // mapping(address => Drug[]) drugsByAddress;
    mapping(uint256 => PurchaseOrder) purchaseOrders;
    mapping(uint256 => Shipment) shipments;

    // 123, manufacturer, la, 0
    // 1234, distributer, la, 1
    // 12345, retailer, la, 2
    // 123456, trans, la, 3
    /**
     * registerCompany() is used to register new entities on the ledger.
     * @param _crn uint256 Company Registration Number (CRN)
     * @param _name string Name of the company
     * @param _location string Location of the company
     * @param _role Role Role of company {Manufacturer, Distributer, Retailer, Transporter}
     */
    function registerCompany(
        uint256 _crn,
        string memory _name,
        string memory _location,
        Roles _role
    ) public returns (bool) {
        require(
            msg.sender != companies[msg.sender].owner,
            "address is already owning a company"
        );
        // myCompany.role = _role;
        companies[msg.sender] = Company(
            _crn,
            msg.sender,
            _name,
            _location,
            _role
        );
        return true;
    }

    // abc, 123, 098, 0987
    /**
     * addDrug() is used by any organisation registered as a ‘manufacturer’ to register a new drug on the ledger.
     * @param _name string Name of the product
     * @param _serialNo uint serial number of drug
     * @param _mfgDate uint256 Date of manufacturing of the drug
     * @param _expDate uint256 Expiration date of the drug
     */
    function addDrug(
        string memory _name,
        uint256 _serialNo,
        uint256 _mfgDate,
        uint256 _expDate
    ) public onlyCompany(msg.sender) returns (bool) {
        uint256 CRN = companies[msg.sender].CRN;
        require(CRN == companies[msg.sender].CRN, "Company Not Registered");
        require(
            companies[msg.sender].role == Roles(0),
            "You must be manufacturer"
        );

        bytes32 drugId = bytes32(sha256(abi.encodePacked(_name, _serialNo)));

        drugs[_name][_serialNo] = Drug(
            drugId,
            _name,
            _serialNo,
            CRN,
            _mfgDate,
            _expDate,
            CRN,
            0
        );
        // drugsByAddress[msg.sender].push(
        //     Drug(drugId, _name, _serialNo, CRN, _mfgDate, _expDate, CRN, 0)
        // );
        return true;
    }

    function getDrugs(
        string memory _drugName,
        uint256 _serialNo
    ) public view returns (Drug memory) {
        return drugs[_drugName][_serialNo];
    }

    // 123, abc, 20
    function createPO(
        uint256 _sellerCRN,
        string memory _drugName,
        uint256 _quantity
    ) public onlyCompany(msg.sender) returns (bool) {
        uint256 buyerCRN = companies[msg.sender].CRN;
        bytes32 id = sha256(abi.encodePacked(buyerCRN, _drugName));
        Roles buyerRole = companies[msg.sender].role;

        require(
            buyerRole != Roles(0),
            "Manufacturer cannot create purchase order"
        );
        require(
            buyerRole != Roles(3),
            "Transporter cannot create purchase order"
        );
        require(buyerCRN != _sellerCRN, "Buyer cannot be a seller");
        purchaseOrders[buyerCRN] = PurchaseOrder(
            id,
            _drugName,
            _quantity,
            buyerCRN,
            _sellerCRN
        );
        return true;
    }

    // 12345, abc, 123456
    function createShipment(
        uint256 _buyerCRN,
        string memory _drugName,
        uint256 _serialNo,
        uint256 _transporterCRN
    ) public onlyCompany(msg.sender) returns (bool) {
        uint256 ownerCRN = companies[msg.sender].CRN;
        Roles sellerRole = companies[msg.sender].role;
        require(
            purchaseOrders[_buyerCRN].sellerCRN == ownerCRN,
            "Order Not Found"
        );
        require(
            sellerRole != Roles(3),
            "Transporter cannot create shipment order"
        );
        // Check whether drugname is same or not
        require(
            sha256(abi.encodePacked(purchaseOrders[_buyerCRN].drugName)) ==
                sha256(abi.encodePacked(_drugName)),
            "Order Not Found"
        );

        uint256 quantity = purchaseOrders[_buyerCRN].quantity;
        bytes32 id = sha256(abi.encodePacked(_buyerCRN, _drugName));
        shipments[_transporterCRN] = Shipment(
            id,
            ownerCRN,
            _drugName,
            _serialNo,
            quantity,
            _transporterCRN,
            Status(0)
        );
        if (drugs[_drugName][_serialNo].currentOwner == ownerCRN) {
            drugs[_drugName][_serialNo].currentOwner = _transporterCRN;
            drugs[_drugName][_serialNo].shipment = _transporterCRN;
        }
        ownerships[_drugName][_serialNo].push(Ownership(_drugName, _serialNo, ownerCRN, _transporterCRN));
        emit OwnerChange(_drugName, _serialNo, ownerCRN, _transporterCRN);
        return true;
    }

    //
    function updateShipment(
        uint256 _buyerCRN,
        string memory _drugName
    ) public returns (bool) {
        uint256 transporterCRN = companies[msg.sender].CRN;
        uint256 serialNo = shipments[transporterCRN].serialNo;
        require(
            companies[msg.sender].CRN != _buyerCRN,
            "Buyer can't update shipment"
        );
        require(
            companies[msg.sender].role == Roles(3),
            "Only transporter can update shipment"
        );
        require(
            companies[msg.sender].CRN == shipments[transporterCRN].transporter,
            "Transporter Not Found"
        );
        require(
            shipments[transporterCRN].transporter == transporterCRN,
            "You do not have any shipment"
        );
        if (
            sha256(abi.encodePacked(shipments[transporterCRN].drugName)) ==
            sha256(abi.encodePacked(_drugName))
        ) {
            require(
                shipments[transporterCRN].status == Status(0),
                "You do not have any shipment to update"
            );
            if (drugs[_drugName][serialNo].currentOwner == transporterCRN) {
                drugs[_drugName][serialNo].currentOwner = _buyerCRN;
                shipments[transporterCRN].status = Status(1);
                // return true;
            }
        } else {
            return false;
        }
        ownerships[_drugName][serialNo].push(Ownership(_drugName, serialNo, transporterCRN, _buyerCRN));
        emit OwnerChange(_drugName, serialNo, transporterCRN, _buyerCRN);
        return true;
    }

    function getShipments()
        public
        view
        onlyCompany(msg.sender)
        returns (Shipment memory)
    {
        // require(companies[msg.sender].role == Roles(3));
        uint256 myCRN = companies[msg.sender].CRN;
        if (shipments[myCRN].status != Status(0)) {}
        return shipments[myCRN];
    }

    /**
     * retailDrug() is called by the retailer while selling the drug to a consumer
     * @param _drugName string
     * @param _serialNumber uint256 serial number of drug
     * @param _customerAadhar uint256
     */
    function retailDrug(
        string memory _drugName,
        uint256 _serialNumber,
        uint256 _customerAadhar
    ) public onlyCompany(msg.sender) returns (bool) {
        uint256 CRN = companies[msg.sender].CRN;
        uint256 currentOwner = drugs[_drugName][_serialNumber].currentOwner;
        require(
            companies[msg.sender].role == Roles(2),
            "You are not a retailer"
        );
        require(currentOwner == CRN, "You must be a current owner of drug"); // Retailer must be current owner of drug
        if (currentOwner == CRN) {
            drugs[_drugName][_serialNumber].currentOwner = _customerAadhar;
            return true;
        }
        ownerships[_drugName][_serialNumber].push(Ownership(_drugName, _serialNumber, CRN, _customerAadhar));
        emit OwnerChange(_drugName, _serialNumber, CRN, _customerAadhar);
        return true;
    }

    /**
     * view the lifecycle of the product by fetching transactions from the blockchain.
     * @param _drugName string
     * @param _serialNo uint256
     * @return Transaction id along with the details of the asset for every transaction associated with it.
     */
    function viewHistory(
        string memory _drugName,
        uint256 _serialNo
    ) public view returns (Ownership[] memory) {
        return ownerships[_drugName][_serialNo];
    }

    /**
     * used to view the current state of the asset
     * @param _drugName string
     * @param _serialNo uint256
     */
    function viewDrugCurrentState(
        string memory _drugName,
        uint256 _serialNo
    ) public view returns (Drug memory) {
        return drugs[_drugName][_serialNo];
    }
}