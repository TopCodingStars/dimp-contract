// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PassportMint.sol";

contract WhitelistPreMint is ERC721Enumerable, Ownable {
    uint256 public pos; //new tokenID
    uint256 public mintSupply; //current nft counts
    uint256 public nftTypeNums;
    mapping(address => uint256) balance;
    mapping(uint256 => string) metadata;
    mapping(uint256 => string) public _data; //the metadata of each nft (tokenID => uri)

    constructor() ERC721("Actocracy Land NFT PreMint", "LandNFTPassMint") {
        pos = 0;
        nftTypeNums = 2;
    }

    //this function let the owner to add or change the uri of nft
    //idx => the type index of the car
    //data => the new nft uri
    function updateMetadata(uint256 idx, string memory data) external onlyOwner {
        require(idx < nftTypeNums, "Out bound of NFT types");
        metadata[idx] = data;
    }

    //anyone can call this function but cannot exceed the total supply
    function mint(address nftOwner, uint256 tokenType) external onlyOwner {
        require(balance[nftOwner] == 0, "Already Minted!");
        require(tokenType < nftTypeNums, "Out bound of NFT types");

        mintSupply += 1;
        balance[nftOwner] += 1;
        pos += 1;
        _data[pos] = metadata[tokenType];
        _safeMint(nftOwner, pos);
    }

    function updateTokenURI(uint256 nftID, string memory data) external onlyOwner {
        _data[nftID] = data;
    }

    //this function returns the token(tokenId)'s uri
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _data[tokenId];
    }
}
