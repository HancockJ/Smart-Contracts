//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


// TODO: Create function to view membership ending time (Yourself, Owner, Admin access only)
// TODO: Create function to manage a users membership period (add or remove time)
// TODO: Create function to withdrawal funds

// TODO: Possibly add a function to allow users to transfer their membership (Maybe with a small fee?)
// TODO: Do we need to list members and their remaining time?

// TODO: Test to make sure modifiers work
// TODO: Create NatSpec style commenting on all functions
// TODO: Add events and emit functions where necessary
// TODO: Make sure all function and variable modifiers are accurate
// TODO: Google how to make sure a contract is secured / best practices

contract NP_premium is AccessControlEnumerable {

    uint constant month = 30 days;

    struct Membership {
        // Starting term price
        uint price; // .05 ether
        // Minimum length in months
        uint[3] tierMinimum; // [1, 3, 12]
        // % of member price you pay per month E.g. 90 = 90% of member price
        uint[3] tierDiscount; // [100, 90, 80]
    }

    Membership membership;

    // Maps users to their membership period end time.
    mapping(address => uint) private memberPool;

    // Creates owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Creates admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// Modifiers

    modifier onlyAdmin {
        require(
            hasRole(ADMIN_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender), "Owner or Admin role required."
        );
        _;
    }

    modifier onlyOwner {
        require(
            hasRole(OWNER_ROLE, msg.sender), "Owner role required."
        );
        _;
    }

    /// Events

    event Deposit(
        address indexed from,
        uint value
    );

    /// Constructor

    constructor(address[] memory admins) {
        // Sets the starting membership values
        membership.price = .05 ether;
        membership.tierMinimum = [1, 3, 12];
        membership.tierDiscount = [100, 90, 80];
        // Grants contract creator full access to contract (OWNER_ROLE)
        _setupRole(OWNER_ROLE, msg.sender);
        // Gives OWNER_ROLE role control over ADMIN_ROLE
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        // Grants ADMIN_ROLE to inputted list of addresses
        for (uint256 i = 0; i < admins.length; i++){
            grantRole(ADMIN_ROLE, admins[i]);
        }
    }

    /// Functions

    receive() external payable {
        register();
    }

    // @param Payment amount received
    // @returns Time added to membership period (in seconds)
    function membershipExtension(uint pay) internal view returns (uint) {
        // cpm = Cost Per Month - How much a tier pays per month
        uint[3] memory cpm = [
            membership.price * membership.tierDiscount[0] / 100,
            membership.price * membership.tierDiscount[1] / 100,
            membership.price * membership.tierDiscount[2] / 100
        ];

        // monthsPayed = months payed for * 1000 (3 decimal place accuracy)
        uint monthsPayed;

        if (pay < (cpm[0] * membership.tierMinimum[0])){
            return 0;
        }
        else if (pay < (cpm[1] * membership.tierMinimum[1])){
            monthsPayed = (pay * 1000) / cpm[0];
        }
        else if (pay < (cpm[2] * membership.tierMinimum[2])){
            monthsPayed = (pay * 1000) / cpm[1];
        } else {
            monthsPayed = (pay * 1000) / cpm[2];
        }
        return monthsPayed * 86400 / 1000;
    }

    // @notice Creates/Extends a users membership, time determined by amount of ether sent
    function register() public payable {
        // TODO: Confirm this works
        // TODO: Confirm rest of logic still works in here
        require(msg.value >= membership.price * membership.tierDiscount[0] * membership.tierMinimum[0] / 100 );
        if(memberPool[msg.sender] <= block.timestamp){
            // Start a new membership
            memberPool[msg.sender] = block.timestamp + membershipExtension(msg.value);
        } else {
            // Extend existing membership
            memberPool[msg.sender] += membershipExtension(msg.value);
            }
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Allows an owner/admin to view all addresses in a specific role
    /// @param role The bytes32 representation of a given role
    function listRole(bytes32 role) public view onlyAdmin returns (address[] memory) {
        uint256 roleCount = getRoleMemberCount(role);

        address[] memory users = new address[](roleCount);

        for (uint256 i = 0; i < roleCount; i++){
            users[i] = getRoleMember(role, i);
        }
        return users;
    }

    /// @notice Checks remaining time on membership.
    /// @return Amount of time remaining in seconds. 0 indicates non-membership.
    function membershipRemaining(address user) public view onlyAdmin returns (uint) {
        return(timeLeft(user));
    }

    /// @notice Shows remaining membership time the calling address has.
    /// @return Amount of time remaining in seconds. 0 indicates non-membership.
    function myMembershipRemaining() public view returns (uint) {
        return timeLeft(msg.sender);
    }

    /// Internal function to give a users time remaining
    function timeLeft(address user) internal view returns (uint) {
        if(memberPool[user] <= block.timestamp){
            return 0;
        }
        return memberPool[user] - block.timestamp;
    }

    /// @notice Extends a users membership time in seconds
    function giftMembership(address user, uint time) external onlyAdmin {
        if(memberPool[user] <= block.timestamp){
            memberPool[user] = block.timestamp += time;
        }
        else{
            memberPool[user] += time;
        }
    }

    // @notice Cancels a users membership
    function cancelMembership(address user) public onlyAdmin {
        memberPool[user] = 0;
    }

    // @notice Allows owner to withdrawal funds held in contract
    function withdraw(uint256 _amount, address _receiver) external onlyOwner {
        payable(_receiver).transfer(_amount);
    }

    // @notice Sets the membership structure for the contract
    function setMembershipPricing(uint _price, uint[3] memory _tierMinimum, uint[3] memory _tierDiscount)  public onlyAdmin  {
        membership.price = _price;
        membership.tierMinimum = _tierMinimum;
        membership.tierDiscount = _tierDiscount;
    }


    // CODE BELOW IS FOR TESTING PURPOSES AND SHOULD BE REMOVED BEFORE PRODUCTION.
    uint storedData;

    function set(uint x) public onlyAdmin {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}
