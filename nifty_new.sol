//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract NP_premium is AccessControlEnumerable {

    uint storedData;

    // Creates owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Creates admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(address[] memory admins) {
        // Grants contract creator full access to contract (OWNER_ROLE)
        _setupRole(OWNER_ROLE, msg.sender);
        // Gives OWNER_ROLE role control over ADMIN_ROLE
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        // Grants ADMIN_ROLE to inputted list of addresses
        for (uint256 i = 0; i < admins.length; i++){
            grantRole(ADMIN_ROLE, admins[i]);
        }
    }

    function listRole(bytes32 role) public view returns (address[] memory){
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender), "Owner or Admin role required.");
        uint256 roleCount = getRoleMemberCount(role);

        address[] memory users = new address[](roleCount);

        for (uint256 i = 0; i < roleCount; i++){
            users[i] = getRoleMember(role, i);
        }

        return users;
    }

    function set(uint x) public {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender), "Owner or Admin role required.");
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
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