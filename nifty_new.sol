//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract NP_premium is AccessControl {

    uint storedData;

    // Create a new role identifier for the owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Create a new role identifier for the admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(address[] admins) {
        // Grants contract creator full access to contract
        _setupRole(OWNER_ROLE, owner);
        // Sets owner rule as admin of admins role
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        // Grants admin role to inputted list of addresses
        for (uint256 i = 0; i < admins.length; i++){
            grantRole(ADMIN_ROLE, admins[i]);
        }
    }

    function listAdmins() returns (address[] admins){
        require(hasRole(ADMIN_ROLE, msg.sender), "Admin role required.");
        uint256 adminCount = getRoleMemberCount(ADMIN_ROLE);

        address[] admins;

        for (uint256 i = 0; i < admins.length; i++){
            admins.push(getRoleMember(ADMIN_ROLE, i));
        }

        return admins;
    }

    function set(uint x) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Admin role required.");
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }


    // Finished access control. Need to test it is working now.



}


/*
    struct user {
        bool isMember;
    }

    mapping(address => Member) public members;

    // Errors that describe failures.

    /// The calling address is not an owner.
    error NotAnOwner();


    // onlyOwner modifier can be added to any function to ensure
    // the function is only ran by an owner.
    modifier onlyOwner() {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                // The msg.sender is an owner and program can proceed.
                _;
            }
        }
        revert NotAnOwner();
    }