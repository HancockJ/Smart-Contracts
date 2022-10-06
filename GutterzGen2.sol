//SPDX-License-Identifier: MIT
/*
Gutterz Gen 2 Mint:

Contract requirements:

- 2,000 supply
- .07 Public Mint

Wallet must hold for a free mint:
- 1 UNUSED Karmeleon
- 1 Gutterz

- Ability to change the price of the public mint
- Look into hardcoding royalties into the contract

UI updates:
- Reuse Gutterz repo
- Display .07 mint price/button if you hold only one Gutterz or one Karmeleon, or neither. Text should read something like "If you hold both a Gutterz and a Karmeleon, you can mint this NFT for free." and have links to mint a Karmeleon & buy a Gutterz
- If user holds both, UI shows free mint with increment counter tied to how many they are eligible for based off of # of Karmeleons held
- Include a karmz-like check to see if a Karmeleon is eligible to mint a Gen 2 free
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @title Gutterz Gen 2 free mint contract
/// @author Jack (@DblJackDiamond) on Twitter
/// @dev
contract Gutterz is ERC721, Ownable, ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // Keeps track of Gutterz species 2 minted so far
    Counters.Counter private supply;

    // Mapping of which Karmeleons have claimed a free mint
    mapping(uint => bool) public CLAIMED;

    // Switch for turning public mint on and off
    bool public PUBLIC_MINT_ON = false;
    // Price if going through public mint
    uint256 public PUBLIC_COST = 0.07 ether;


    bool public paused = true;
    bool public revealed = false;
    string public NOT_REVEALED_URI = "ipfs://QmXzWaAMQgGVkACu4Yxbhd28Y1sMw6FW2hW7NaEVbEiu2o/hidden.json";


    string public uriPrefix = "";
    string public uriSuffix = ".json";

    string public _name = "Gutterz Species 2";
    string public _symbol = "GTRZ2";
    uint256 public MAX_SUPPLY = 1000;


    IERC721Enumerable public KARMELEONS_ADDRESS = IERC721Enumerable(0x950b9476a4de757BB134483029AC4Ec17E739e3A);
    IERC721Enumerable public GUTTERZ_ADDRESS = IERC721(0xB71b0a17E21a0D1BF4f07858bCd6B18A985467e5);


    constructor() ERC721(_name, _symbol) {}

    modifier mintCompliance(uint256 _amount) {
        require(supply.current() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
        require(_amount > 0, "Invalid mint amount!");
        _;
    }

    /// @param _address Address of account to check for a Gutterz Species 1
    /// @return bool True if the address owns a Gutter animal with that ID
    function hasGutterz(address _address) public view returns (bool) {
        if(GUTTERZ_ADDRESS.balanceOf(_address) > 0 ){
            return true;
        }
        return false;
    }

    /// @return uint The amount of Gutterz species 2 minted
    function totalSupply() public view returns (uint) {
        return supply.current();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////// 3 Mint types - free, public, and owner //////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Checks to make sure msg.sender is eligible to mint the desired amount of Gutterz
    /// @param _amount How many Gutterz to mint
    function holdersMint(uint _amount) public mintCompliance(_amount) nonReentrant {
        require(hasGutterID(msg.sender), "You need to own a Gutterz Species 1 to mint a Gutterz species 2 for free!");
        uint[] memory freeMintsRemaining = unusedKarmeleons(msg.sender);
        require(freeMintsRemaining.length >= _numberOfTokens, "You don't own enough unused Karmeleons!");
        require(!paused, "The contract is paused!");
        for(uint i=0; i < _amount; i++) {
            supply.increment();
            _mint(msg.sender, supply.current());
        }
    }

    /// @notice Public mint for those that do not qualify for a free mint
    /// @param _amount How many Gutterz to mint
    function publicMint(uint _amount) public payable mintCompliance(_amount) nonReentrant {
        require(PUBLIC_MINT_ON, "Minting only available to eligible holders right now");
        require(msg.value >= PUBLIC_COST * _mintAmount, "Insufficient payment sent to mint");
        require(!paused, "The contract is paused!");
        for(uint i=0; i < _amount; i++) {
            supply.increment();
            _mint(msg.sender, supply.current());
        }
    }

    /// @notice Allows the owner (Karmelo) to mint without restrictions
    function ownerMint(uint _amount, address _to) public onlyOwner mintCompliance(_amount) {
        for(uint i=0; i < _amount; i++) {
            supply.increment();
            _mint(_to, supply.current());
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////

    /// @return address[] A list of all owner addresses from 1 to totalSupply()
    function getAllOwners() public view onlyOwner returns (address[] memory){
        address[] memory gutterzOwners = new address[](totalSupply());
        for(uint i=1; i <= totalSupply(); i++){
            gutterzOwners[i -1] = ownerOf(i);
        }
        return gutterzOwners;
    }


    /// @notice Retrieves the Karmeleons in owners account then returns karmeleons not been used for a free claim.
    /// @param _owner Address of account to check for Karmeleons
    /// @return uint[] Array of Eligible karmeleons by ID.
    function unusedKarmeleons(address _owner) internal view returns (uint[] memory) {
        uint ownedKarmeleonCount;
        uint validKarmeleonCount;
        uint ownedKarmeleonCount = IERC721Enumerable(KARMELEONS_ADDRESS).balanceOf(msg.sender);
        uint validKarmeleonCount = 0;
        for(uint i=0; i < ownedKarmeleonCount; i++){
            if(!CLAIMED[IERC721Enumerable(KARMELEONS_ADDRESS).tokenOfOwnerByIndex(_owner, i)]){
                //Karmeleon is valid for mint
                validKarmeleonCount++;
            }
        }
        uint[] memory validKarmeleons = new uint[](validKarmeleonCount);
        for(uint i=0; i < ownedKarmeleonCount; i++){
            uint karmeleonID = IERC721Enumerable(KARMELEONS_ADDRESS).tokenOfOwnerByIndex(_owner, i);
            if(!CLAIMED[karmeleonID]){
                validKarmeleons[validKarmeleonCount - 1] = karmeleonID;
                validKarmeleonCount--;
            }
        }
        return validKarmeleons;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(!revealed) {
            return NOT_REVEALED_URI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        PUBLIC_COST = _newCost;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    /// @notice Allows owner to start and stop minting process
    /// @param _state true = paused, false = not paused
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

}


