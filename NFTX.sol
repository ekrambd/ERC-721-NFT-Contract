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
    mapping(uint256 => bool) private tokenExistsMapping;

    event NFTMinted(address indexed owner, uint256 indexed tokenId, string title, uint256 price);
    event NFTUpdated(uint256 indexed tokenId, string title, string description, uint256 price, string imageURI);
    event NFTDeleted(uint256 indexed tokenId);
    event TransferEnabled(address indexed account);

    constructor() ERC721("NFTX", "NFX") Ownable(msg.sender) {}

    function setTransfersEnabled(bool enabled) external onlyOwner {
        transfersEnabled = enabled;
        emit TransferEnabled(msg.sender);
    }

    function mint(
        string memory title,
        string memory description,
        string memory imageURI,
        uint256 price,
        string memory tokenURI
    ) external payable nonReentrant {
        require(msg.value >= price, "Insufficient Balance");
        uint256 tokenId = nextTokenId;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nftData[tokenId] = NFTData(title, description, imageURI, price);
        tokenExistsMapping[tokenId] = true;
        nextTokenId++;
        emit NFTMinted(msg.sender, tokenId, title, price);
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return tokenExistsMapping[tokenId];
    }

    function editNFT(
        uint256 tokenId,
        string memory newTitle,
        string memory newDescription,
        string memory newImageURI,
        uint256 newPrice
    ) external onlyOwner {
        require(tokenExists(tokenId), "NFT does not exist");
        nftData[tokenId] = NFTData(newTitle, newDescription, newImageURI, newPrice);
        emit NFTUpdated(tokenId, newTitle, newDescription, newPrice, newImageURI);
    }

    function deleteNFT(uint256 tokenId) external onlyOwner {
        require(tokenExists(tokenId), "NFT does not exist");
        delete nftData[tokenId];
        _burn(tokenId);
        tokenExistsMapping[tokenId] = false;
        emit NFTDeleted(tokenId);
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

    function fullFundWithdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    function withdrawAmount(uint256 amount) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(amount > 0, "Amount must be > 0");
        require(amount <= balance, "Not enough balance");
        payable(owner()).transfer(amount);
    }
}
