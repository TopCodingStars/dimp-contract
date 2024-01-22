// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PassportMint.sol";

contract LandNFTPass is ERC721Enumerable, Ownable {
    uint256 public pos; //new tokenID
    uint256 public mintSupply; //current nft counts
    uint256 public maxMintSupply; //nft count limit
    string[] public metadata; //array that stores the uri of 5 types cars
    uint256 public price; //nft price
    mapping(uint256 => string) public _data; //the metadata of each nft (tokenID => uri)
    mapping(address => uint256) public _mintAmount; //

    PassportMint public passport;
    IERC20 matic;

    constructor(
        PassportMint _passport,
        IERC20 _matic
    ) ERC721("Actocracy Land NFT Pass", "LandNFTPassMint") {
        pos = 0;
        maxMintSupply = 237 * 10 ** 9;
        passport = _passport;
        price = 1 * 10 ** 17; // 0.1 MATIC
        matic = _matic;
    }

    //this function let the owner to add or change the uri of nft
    //idx => the type index of the car
    //data => the new nft uri
    function updateMetadata(uint256 idx, string memory data) external onlyOwner {
        require(idx >= 0 && idx < 5, "Invalid Type");
        metadata[idx] = data;
    }

    //this function let the owner to set the price of the nft (busd)
    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    //extense the maxSupply if owner wants
    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > maxMintSupply, "That amount already exists");
        maxMintSupply = _maxSupply;
    }

    //anyone can call this function but cannot exceed the total supply
    function mint(uint256 nftAmount) external payable {
        uint256 passportID = passport._nftIdByAddr(msg.sender);
        require(passportID > 0, "You don't have Actocracy Passport!");

        uint256 mintableAmount;
        (, , string memory _referer, , , uint256 referralCount, uint256 level) = passport
            ._totalInfo(passportID);
        if (level == 1) {
            mintableAmount = (1 + referralCount) - _mintAmount[msg.sender];
        } else {
            mintableAmount = (2 + referralCount) - _mintAmount[msg.sender];
        }

        require(mintableAmount >= nftAmount, "Invalid Amount");
        require(mintSupply + nftAmount <= maxMintSupply, "Mint: exceed mint supply");
        require(msg.value >= (price * nftAmount), "Not Enough Fund");

        uint256 feeAmount;

        if (keccak256(abi.encodePacked(_referer)) != keccak256(abi.encodePacked("no"))) {
            uint256 fpassportID = passport._nftIdByReferral(_referer);
            (address _fownerAddr, , string memory _freferer, , , , ) = passport._totalInfo(
                fpassportID
            );
            require(_fownerAddr != address(0), "No referer");
            payable(_fownerAddr).transfer((msg.value * 7) / 100);
            feeAmount = feeAmount + ((msg.value * 7) / 100);
            if (keccak256(abi.encodePacked(_freferer)) != keccak256(abi.encodePacked("no"))) {
                uint256 spassportID = passport._nftIdByReferral(_freferer);
                (address _sownerAddr, , string memory _sreferer, , , , ) = passport._totalInfo(
                    spassportID
                );
                require(_sownerAddr != address(0), "No referer");
                payable(_sownerAddr).transfer((msg.value * 5) / 100);
                feeAmount = feeAmount + ((msg.value * 5) / 100);
                if (keccak256(abi.encodePacked(_sreferer)) != keccak256(abi.encodePacked("no"))) {
                    uint256 tpassportID = passport._nftIdByReferral(_sreferer);
                    (address _townerAddr, , , , , , ) = passport._totalInfo(tpassportID);
                    require(_townerAddr != address(0), "No referer");
                    payable(_townerAddr).transfer((msg.value * 3) / 100);
                    feeAmount = feeAmount + ((msg.value * 3) / 100);
                }
            }
        }

        _mintAmount[msg.sender] += nftAmount;
        mintSupply += nftAmount;

        for (uint256 i = 0; i < nftAmount; i = i + 1) {
            pos = pos + 1;
            _safeMint(msg.sender, pos);
        }
    }

    function updateTokenURI(uint256 nftID, string memory data) external onlyOwner {
        _data[nftID] = data;
    }

    //this function returns the token(tokenId)'s uri
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _data[tokenId];
    }

    function viewBalance(address account) public view returns (uint256) {
        return _mintAmount[account];
    }

    function viewMintableAmount(address account) public view returns (uint256) {
        uint256 mintableAmount;
        uint256 passportID = passport._nftIdByAddr(account);
        (, , , , , uint256 referralCount, uint256 level) = passport._totalInfo(passportID);
        if (passportID == 0) {
            mintableAmount = 0;
        } else {
            if (level == 1) {
                mintableAmount = (1 + referralCount) - _mintAmount[msg.sender];
            } else {
                mintableAmount = (2 + referralCount) - _mintAmount[msg.sender];
            }
        }
        return mintableAmount;
    }

    //ownable function that transfers the funds in this contract to the owner's wallet
    function withdrawFunds(address recipient) external onlyOwner {
        uint256 maticBalance = matic.balanceOf(address(this));
        matic.transfer(recipient, maticBalance);
    }
}
