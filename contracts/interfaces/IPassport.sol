// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPassport {
    struct infoData {
        address ownerAddr;
        string email;
        string referer; //referer's referral link
        string referral; //holder's own link
        uint256 nftID;
        uint256 referralCount;
        uint256 level;
    }

    function _nftIdByAddr(address account) external view returns (uint256);
    function _totalInfo(uint256 nftID) external view returns (infoData memory);
    function _nftIdByReferral(string memory referral) external view returns (uint256);

    //this function let the owner to add or change the uri of nft
    //idx => the type index of the car
    //data => the new nft uri
    // function updateMetadata(uint256 idx, string memory data) external onlyOwner {
    // 	require(idx >= 0 && idx <5, "Invalid Type");
    // 	metadata[idx] = data;
    // }

    function viewData(address account) external view returns (infoData memory);

    function viewReferralCount(address account) external view returns (uint256);

    //this function returns the token(tokenId)'s uri
    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    // 	return _data[tokenId];
    // }
}
