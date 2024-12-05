// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage{

    using Counters for Counters.Counter;

    Counters.Counter _tokenIds;

    constructor() ERC721 ("NFT","NFT") {}



    function mint(string memory _tokenURI) external returns(uint) {

        _tokenIds.increment();

        _safeMint(msg.sender, _tokenIds.current());
 
 
        _setTokenURI(_tokenIds.current(), _tokenURI);

        return _tokenIds.current();

    }


}