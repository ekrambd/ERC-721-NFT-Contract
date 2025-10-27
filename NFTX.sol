// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTX is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextTokenId = 1;
    bool public transfersEnabled = false;

    struct NFTData {
        string title;
        string description;
        string imageURI;
        uint256 price;
    }

    mapping(uint256 => NFTData) public nftData;
    mapping(uint256 => string) private tokenURIs;
    mapping(uint256 => bool) private metadataExists;
    mapping(uint256 => bool) public isMinted;

    event NFTAdded(uint256 indexed tokenId, string title, uint256 price);
    event NFTMinted(address indexed user, uint256 indexed tokenId);
    event TransferEnabled(address indexed account);

    constructor() ERC721("NFTX", "NFX") Ownable(msg.sender){}

    function setTransfersEnabled(bool enabled) external onlyOwner {
        transfersEnabled = enabled;
        emit TransferEnabled(msg.sender);
    }

    function addNFTMetadata(
        string memory title,
        string memory description,
        string memory imageURI,
        uint256 price,
        string memory tokenURI
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;
        nftData[tokenId] = NFTData(title, description, imageURI, price);
        tokenURIs[tokenId] = tokenURI;
        metadataExists[tokenId] = true;
        nextTokenId++;

        emit NFTAdded(tokenId, title, price);
    }

    function mintNFT(uint256 tokenId) external payable nonReentrant {
        require(metadataExists[tokenId], "NFT metadata not exists");
        require(!isMinted[tokenId],"Already Minted");
        NFTData memory nft = nftData[tokenId];
        require(msg.value >= nft.price, "Insufficient MATIC");

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURIs[tokenId]);

        isMinted[tokenId] = true;

        emit NFTMinted(msg.sender, tokenId);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            require(transfersEnabled, "Transfers are disabled");
        }
        return super._update(to, tokenId, auth);
    }
}
