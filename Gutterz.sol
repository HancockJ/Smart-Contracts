//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @title Gutterz free mint contract
/// @author Jack Hancock (@DblJackDiamond)
/// @dev All function calls are currently implemented without side effects
contract Gutterz is ERC721, Ownable, ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    uint256 public MAX_SUPPLY = 3000;
    IERC1155 public CATS_ADDRESS = IERC1155(0xEdB61f74B0d09B2558F1eeb79B247c1F363Ae452);
    IERC1155 public RATS_ADDRESS = IERC1155(0xD7B397eDad16ca8111CA4A3B832d0a5E3ae2438C);
    IERC721Enumerable public PIGEONS_ADDRESS = IERC721Enumerable(0x950b9476a4de757BB134483029AC4Ec17E739e3A);
    IERC721Enumerable public DOGS_ADDRESS = IERC721Enumerable(0x6E9DA81ce622fB65ABf6a8d8040e460fF2543Add);


    mapping(address => uint) public CLAIM_COUNT;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        
    }

    modifier mintCompliance(uint256 _amount) {
        require(supply.current() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
        require(_amount > 0, "Invalid mint amount!");
        _;
    }

    /// @param _address Address of account to check for a Gutter Animal
    /// @param _id The ID of a Gutter Animal that the user says they own
    /// @return bool True if the address owns a Gutter animal with that ID
    function hasGutterID(address _address, uint _id) public view returns (bool) {
        if(CATS_ADDRESS.balanceOf(_address, _id) > 0 ){
            return true;
        }
        if(RATS_ADDRESS.balanceOf(_address, _id) > 0 ){
            return true;
        }
        if(PIGEONS_ADDRESS.balanceOf(_address) > 0 ){
            return true;
        }
        if(DOGS_ADDRESS.balanceOf(_address) > 0 ){
            return true;
        }
        return false;
    }

    /// @return uint The amount of Gutterz minted
    function totalSupply() public view returns (uint) {
        return supply.current();
    }

    /// @notice Checks to make sure msg.sender is eligible to mint the desired amount of Gutterz
    /// @param _amount How many Gutterz to mint
    function mint(uint _amount, uint _id) public mintCompliance(_amount) nonReentrant {
        require(hasGutterID(msg.sender, _id), "You need to own a Gutter Animal to mint a Gutterz!");
        require(3 - CLAIM_COUNT[msg.sender] - _amount >= 0, "You can only claim 3 Gutterz per wallet.");
        for(uint i=0; i < _amount; i++) {
            CLAIM_COUNT[msg.sender] += 1;
            supply.increment();
            _mint(msg.sender, supply.current());
        }
    }

    /// @notice Allows the owner to mint more than the wallet limit 
    function ownerMint(uint _amount, address _to) public onlyOwner mintCompliance(_amount) {
        for(uint i=0; i < _amount; i++) {
            CLAIM_COUNT[msg.sender] += 1;
            supply.increment();
            _mint(_to, supply.current());
        }
    }

    /// @return address[] A list of all owner addresses from 1 to totalSupply()
    function getAllOwners() public view onlyOwner returns (address[] memory){
        address[] memory gutterzOwners = new address[](totalSupply());
        for(uint i=1; i <= totalSupply(); i++){
            gutterzOwners[i -1] = ownerOf(i);
        }
        return gutterzOwners;
    }

}

