// SPDX-License-Identifier: MIT
// Amended by Jack Hancock (@DblJackDiamond)

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract KarmeleonsFreeMint is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    address public KARMELEON_ADDRESS;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public MAX_SUPPLY = 3333;
    uint256 MINT_SUPPLY;

    mapping(uint => bool) CLAIMED;

    bool public paused = false;

    constructor(string memory _name, string memory _symbol, address _karmeleonAddress) ERC721(_name, _symbol) {
        KARMELEON_ADDRESS = _karmeleonAddress;
    }

    modifier mintCompliance(uint256 _numberOfTokens) {
        require(supply.current() + _numberOfTokens <= MAX_SUPPLY, "Max supply exceeded!");
        require(_numberOfTokens > 0, "Invalid mint amount!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    // Returns 2 numbers: The amount of Karmeleons the address has &
    // the amount of karmeleons they have still eligible for free mint.
    function karmeleonCount(address _owner) public view returns (uint, uint) {
        uint ownedKarmeleonCount = IERC721Enumerable(KARMELEON_ADDRESS).balanceOf(msg.sender);
        uint validKarmeleonCount = 0;
        for(uint i=0; i < ownedKarmeleonCount; i++){
            if(!CLAIMED[IERC721Enumerable(KARMELEON_ADDRESS).tokenOfOwnerByIndex(_owner, i)]){
                //Karmeleon is valid for mint
                validKarmeleonCount++;
            }
        }
        return (ownedKarmeleonCount, validKarmeleonCount);
    }


    // Retrieves the Karmeleons in owners account then returns karmeleons not been used for a free claim.
    function remainingMints(address _owner) internal view returns (uint256[] memory) {
        uint ownedKarmeleonCount;
        uint validKarmeleonCount;
        (ownedKarmeleonCount, validKarmeleonCount) = karmeleonCount(_owner);
        uint[] memory validKarmeleons = new uint[](validKarmeleonCount);
        for(uint i=0; i < ownedKarmeleonCount; i++){
            uint karmeleonID = IERC721Enumerable(KARMELEON_ADDRESS).tokenOfOwnerByIndex(_owner, i);
            if(!CLAIMED[karmeleonID]){
                validKarmeleons[validKarmeleonCount - 1] = karmeleonID;
                validKarmeleonCount--;
            }
        }
        return validKarmeleons;
    }


    function mint(uint256 _numberOfTokens) public payable mintCompliance(_numberOfTokens) {
        require(!paused, "The contract is paused!");
        uint[] memory mintsRemaining = remainingMints(msg.sender);
        require(mintsRemaining.length >= _numberOfTokens, "You don't own enough non-claimed Karmeleons!");
        for(uint i=0; i < _numberOfTokens; i++) {
            CLAIMED[mintsRemaining[i]] = true;
            supply.increment();
            _mint(msg.sender, supply.current());
        }
    }


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

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
