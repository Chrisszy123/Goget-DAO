pragma solidity ^0.8.1;

interface IFakeNFTMarket {
    // purchase nft from the marketplace
    function purchase(uint256 _tokenId) external payable;

    // get the nnft price
    function getPrice() external view returns (uint256);

    // check available nfts
    function available(uint256 _tokenId) external view returns (bool);
}
