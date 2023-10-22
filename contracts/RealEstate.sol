// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RealEstate {
    enum Status {
        NotExist,
        Approved,
        Rejected,
        Pending
    }
    enum Role {
        visitor,
        user,
        admin,
        superAdmin
    }

    // Propert Attributes
    struct PropertyDetail {
        Status status;
        uint256 value;
        address owner;
    }

    mapping(uint256 => PropertyDetail) Properties; //For Properties
    mapping(address => Role) userRoles;
    mapping(address => bool) verifiedUsers;
    mapping(uint => address) PropertyOwnerChange; //To store the Property Ownership Change Request

    // Initializing
    constructor() {
        address createrAddress = msg.sender;
        userRoles[createrAddress] = Role.superAdmin;
        verifiedUsers[createrAddress] = true;
    }

    modifier verifiedAdmin() {
        require(
            userRoles[msg.sender] >= Role.admin && verifiedUsers[msg.sender],
            "You are not allowed to do this"
        );
        _;
    }
    modifier verifiedSuperAdmin() {
        require(
            userRoles[msg.sender] >= Role.superAdmin &&
                verifiedUsers[msg.sender],
            "You are not allowed to do this"
        );
        _;
    }

    function addUser(
        address _userAddress
    ) external verifiedAdmin returns (bool) {
        require(userRoles[_userAddress] != Role.user, "User already exists");
        userRoles[_userAddress] = Role.user;
        verifiedUsers[_userAddress] = false;
        return true;
    }

    function addAdmin(
        address _userAddress
    ) external verifiedAdmin returns (bool) {
        require(userRoles[_userAddress] != Role.admin, "Admin already exists");
        userRoles[_userAddress] = Role.admin;
        verifiedUsers[_userAddress] = true;
        return true;
    }

    modifier onlyOwner(uint propId) {
        require(
            Properties[propId].status != Status.NotExist &&
                Properties[propId].owner == msg.sender
        );
        _;
    }
    modifier isVerified(address _userAddress) {
        require(verifiedUsers[_userAddress] == true);
        _;
    }

    function addSuperAdmin(
        address _userAddress
    ) external verifiedSuperAdmin returns (bool) {
        require(
            userRoles[_userAddress] != Role.admin,
            "SuperAdmin already exists"
        );
        userRoles[_userAddress] = Role.superAdmin;
        verifiedUsers[_userAddress] = true;
        return true;
    }

    function changeOwnerShip(
        uint propId,
        address _newUser
    ) external onlyOwner(propId) isVerified(_newUser) returns (bool) {
        require(Properties[propId].owner != _newUser);
        require(PropertyOwnerChange[propId] == address(0));
        PropertyOwnerChange[propId] = _newUser;
        return true;
    }

    function approveChangeOwnership(
        uint propId
    ) external verifiedSuperAdmin returns (bool) {
        require(Properties[propId].status != Status.NotExist);
        require(PropertyOwnerChange[propId] != address(0));
        Properties[propId].owner = PropertyOwnerChange[propId];
        PropertyOwnerChange[propId] = address(0);
        return true;
    }

    function addProperty(
        uint propId,
        uint _value,
        address _owner
    ) external verifiedAdmin returns (bool) {
        require(
            Properties[propId].status == Status.NotExist,
            "Property already exists at this Id"
        );
        Properties[propId] = PropertyDetail(Status.Pending, _value, _owner);
        return true;
    }

    function getPropertyDetail(
        uint propId
    ) public view returns (Status, uint, address) {
        return (
            Properties[propId].status,
            Properties[propId].value,
            Properties[propId].owner
        );
    }

    function isUserVerified(address _userAddress) public view returns (bool) {
        return (verifiedUsers[_userAddress]);
    }

    function approveProperty(
        uint propId
    ) external verifiedAdmin returns (bool) {
        require(
            Properties[propId].owner != msg.sender,
            "You can't approve your own property"
        );
        Properties[propId].status = Status.Approved;
        return true;
    }

    function rejectProperty(uint propId) external verifiedAdmin returns (bool) {
        require(
            Properties[propId].owner != msg.sender,
            "You can't reject your own property"
        );
        Properties[propId].status = Status.Rejected;
        return true;
    }

    function verifyUser(
        address _userAddress
    ) external verifiedAdmin returns (bool) {
        require(userRoles[_userAddress] != Role.visitor, "User not found");
        verifiedUsers[_userAddress] = true;
        return true;
    }

    function unVerifyUser(
        address _userAddress
    ) external verifiedAdmin returns (bool) {
        require(userRoles[_userAddress] != Role.visitor, "User not found");
        verifiedUsers[_userAddress] = false;
        return true;
    }
}
