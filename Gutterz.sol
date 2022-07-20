//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


/// @title Gutterz free mint contract
/// @author Jack Hancock (@DblJackDiamond)
/// @dev All function calls are currently implemented without side effects
contract Gutterz is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    uint256 public MAX_SUPPLY = 3000;

    address public CATS_ADDRESS = 0x66C8f2Aa66e5745D62D4920Fc40d2662042Cc688;
    address public RATS_ADDRESS = 0x66C8f2Aa66e5745D62D4920Fc40d2662042Cc688;
    address public PIGEONS_ADDRESS = 0x66C8f2Aa66e5745D62D4920Fc40d2662042Cc688;
    address public DOGS_ADDRESS = 0x66C8f2Aa66e5745D62D4920Fc40d2662042Cc688;

    mapping(address => uint) public CLAIM_COUNT;

    constructor(string memory _name, string memory _symbol /*, address _catsAddress*/) ERC721(_name, _symbol) {
        //CATS_ADDRESS = _catsAddress;
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
        if(ERC1155(CATS_ADDRESS).balanceOf(_address, _id) > 0 ){
            return true;
        }
        if(ERC1155(RATS_ADDRESS).balanceOf(_address, _id) > 0 ){
            return true;
        }
        if(ERC1155(PIGEONS_ADDRESS).balanceOf(_address, _id) > 0 ){
            return true;
        }
        if(ERC1155(DOGS_ADDRESS).balanceOf(_address, _id) > 0 ){
            return true;
        }
        return false;
    }

    /// @return uint The amount of Karmz minted
    function totalSupply() public view returns (uint) {
        return supply.current();
    }

    /// @notice Checks to make sure msg.sender is eligible to mint the desired amount of Gutterz
    /// @param _amount How many Gutterz to mint
    function mint(uint _amount, uint _id) public mintCompliance(_amount) {
        require(hasGutterID(msg.sender, _id), "You need to own a Gutter Animal to mint a Gutterz!");
        require(3 - CLAIM_COUNT[msg.sender] - _amount >= 0, "You can only claim 3 Gutterz per wallet.");
        for(uint i=0; i < _amount; i++) {
            CLAIM_COUNT[msg.sender] += 1;
            supply.increment();
            _mint(msg.sender, supply.current());
        }
    }

    /// @notice Allows the owner to mint unlimited Gutterz :)
    function sudoMint(uint _amount, address _to) public onlyOwner mintCompliance(_amount) {
        for(uint i=0; i < _amount; i++) {
            CLAIM_COUNT[msg.sender] += 1;
            supply.increment();
            _mint(_to, supply.current());
        }
    }

}



