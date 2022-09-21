// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract FakeNFTMarket {
    ///@dev maintain a fake mapping for tokenids of NFT to addresses
    mapping(uint256 => address) public tokenIdToAddress;
    ///@dev set the purchase price for each nft
    uint256 constant PRICE = 0.01 ether;

    ///@dev the purchase() allows a user to purchase an nft with the unique ID and sets the caller as the owner
    function purchase(uint256 _tokenId) external payable {
        // check that the sent amount is 0.01eth or higher
        require(msg.value >= PRICE, "You need more ETH");
        // set the token id to the caller of the function
        tokenIdToAddress[_tokenId] = msg.sender;
    }

    // getter function to return price of NFT
    function getPrice() public view returns (uint256) {
        return PRICE;
    }

    ///@dev check using the id to know if an NFT is available
    function available(uint256 _tokenId) external view returns (bool) {
        // address(0) = 0x0000000000000000000000000000000000000000
        // This is the default value for addresses in Solidity
        if(tokenIdToAddress[_tokenId] == address(0)){
            return true;
        }
        return false;
    }
}
