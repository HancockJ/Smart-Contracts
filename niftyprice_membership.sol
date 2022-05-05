//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


/// @title Membership system for NP Premium
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
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
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
        return monthsPayed * month / 1000;
    }

    // @notice Creates/Extends a users membership, time determined by amount of ether sent
    function register() public payable {
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

    /// @notice Checks remaining time on a users membership.
    /// @param user Address of user to check membership
    /// @return Amount of time remaining in seconds. 0 indicates non-membership.
    function membershipRemaining(address user) public view returns (uint) {
        return(timeLeft(user));
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
            memberPool[user] = block.timestamp + time;
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

    // @notice js example - np.setMembershipPricing("50000000000000000",[1,3,12],[100,80,50])
    // @param _price the price per month (in wei) (1000000000000000000 = 1 ether)
    // @param _tierMinimum an array of 3 uints, the amount of months for each tier I.E. [1,3,12] = 1/3/12 month tiers
    // @param _tierDiscount an array of 3 uints, the % you must pay for each tier I.E. [100,90,80] = 100%,90%,80% of price per month that each tier pays
    // @notice Sets the membership structure for the contract
    function setMembershipPricing(uint _price, uint[3] memory _tierMinimum, uint[3] memory _tierDiscount)  public onlyAdmin  {
        membership.price = _price;
        membership.tierMinimum = _tierMinimum;
        membership.tierDiscount = _tierDiscount;
    }

    // @return Array of the 7 price settings: [price, tierMinimum[0], tierMinimum[1], tierMinimum[2], tierDiscount[0], tierDiscount[1], tierDiscount[2]
    function viewMembershipPricing() public view returns (uint[7] memory){
        return [membership.price, membership.tierMinimum[0], membership.tierMinimum[1], membership.tierMinimum[2], membership.tierDiscount[0], membership.tierDiscount[1], membership.tierDiscount[2]];
    }
}
