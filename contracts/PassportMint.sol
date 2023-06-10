// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PassportMint is ERC721Enumerable, Ownable {
	struct infoData {
        address ownerAddr;
        string email;
        string referer; //referer's referral link
        string referral; //holder's own link
        uint256 nftID;
        uint256 referralCount;
        uint256 level;
    }

	uint256 public pos;	//new tokenID
	string[] public metadata;	//array that stores metadata
	mapping(address => uint256) public _nftIdByAddr;	//for check if already used for passport && to show data for passport holder
	mapping(string => uint256) public _nftIdByEmail;	//for check if already used for passport
    mapping(string => uint256) public _nftIdByReferral;  //for count up referer's referral count && set level
    mapping(uint256 => infoData) public _totalInfo; //nftID => data

	constructor() ERC721("Actocracy Passport Issue", "PASSPORTNFT") {
		pos = 0;
	}

	//this function let the owner to add or change the uri of nft
	//idx => the type index of the car
	//data => the new nft uri
	// function updateMetadata(uint256 idx, string memory data) external onlyOwner {
	// 	require(idx >= 0 && idx <5, "Invalid Type");
	// 	metadata[idx] = data;
	// }

	//anyone can call this function but cannot exceed the total supply
	function mint(string memory referer, string memory ownReferralLink, string memory email) external {
		require(_nftIdByAddr[msg.sender] == 0 && _nftIdByEmail[email] == 0, "Your account has already used for passport!");
        require(_nftIdByReferral[ownReferralLink] == 0, "Invalid Referral Link");
        require(_nftIdByReferral[referer] > 0 || keccak256(abi.encodePacked(referer)) == keccak256(abi.encodePacked("no")), "Your referer is invalid");
        pos = pos + 1;
        uint256 levelTemp;
        if(keccak256(abi.encodePacked(referer)) == keccak256(abi.encodePacked("no"))) {
            levelTemp = 1;
        } else {
            _totalInfo[_nftIdByReferral[referer]].referralCount = _totalInfo[_nftIdByReferral[referer]].referralCount + 1;
            if(keccak256(abi.encodePacked(_totalInfo[_nftIdByReferral[referer]].referer)) == keccak256(abi.encodePacked("no"))) {
                levelTemp = 2;
            } else{
                levelTemp = 3;
            }
        }
        _nftIdByAddr[msg.sender] = pos;
        _nftIdByEmail[email] = pos;
        _nftIdByReferral[ownReferralLink] = pos;
        infoData memory temp;
        temp.ownerAddr = msg.sender;
        temp.email = email;
        temp.referer = referer;
        temp.referral = ownReferralLink;
        temp.nftID = pos;
        temp.level = levelTemp;
        temp.referralCount = 0;
        _totalInfo[pos] = temp;
	}

    function viewData(address account) public view returns(infoData memory) {
        uint256 nftID = _nftIdByAddr[account];
        return _totalInfo[nftID];
    }

    function viewReferralCount(address account) public view returns(uint256) {
        uint256 nftID = _nftIdByAddr[account];
        return _totalInfo[nftID].referralCount;
    }



	//this function returns the token(tokenId)'s uri
	// function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
	// 	return _data[tokenId];
	// }

}