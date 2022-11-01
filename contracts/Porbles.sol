// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Ownable.sol";
import "./lib/ERC721.sol";
import "./lib/ERC2981.sol";
import "./lib/IERC20.sol";
import "./lib/SafeERC20.sol";
import "./lib/Counters.sol";

contract Porbles is ERC721, ERC2981, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // address of payToken to buy Porble NFT. For i.e 10 wavax
    address public payToken;

    // price of nft item
    uint256 public pricePerItem;

    // id of last nft
    Counters.Counter public nftIdPointer;

    event PayTokenChanged(
        address indexed oldPayToken,
        address indexed newPayToken
    );

    event ItemPriceChanged(uint256 oldPrice, uint256 newPrice);

    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 price,
        uint256 timestamp
    );

    constructor() ERC721("Porble NFT", "PNFT") {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Set address of PayToken to buy Porble NFT
     * @param _payToken the address of new PayToken
     */
    function setPayToken(address _payToken) external onlyOwner {
        address oldPayToken = payToken;
        payToken = _payToken;
        emit PayTokenChanged(oldPayToken, _payToken);
    }

    /**
     * Set address of PayToken to buy Porble NFT
     * @param _pricePerItem price per NFT item
     */
    function setNftPrice(uint256 _pricePerItem) external onlyOwner {
        uint256 oldPrice = pricePerItem;
        pricePerItem = _pricePerItem;
        emit ItemPriceChanged(oldPrice, _pricePerItem);
    }

    /**
     * Mint NFT to caller
     */
    function mint() external {
        require(payToken != address(0), "Error: pay token not set");
        require(pricePerItem != 0, "Error: price not set");

        // Transfer payToken to owner
        IERC20(payToken).safeTransferFrom(msg.sender, owner(), pricePerItem);

        // mint nft to a caller
        uint256 tokenId = nftIdPointer.current();
        _safeMint(msg.sender, tokenId);
        nftIdPointer.increment();

        emit NFTMinted(msg.sender, tokenId, pricePerItem, block.timestamp);
    }

    /**
     * Set default royalty
     * @param _receiver address or receiver
     * @param _feeDenominator value of fee Denominator
     */
    function setDefaultRoyalty(address _receiver, uint96 _feeDenominator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeDenominator);
    }

    /**
     * Set token royalty information
     * @param _tokenId id of nft item
     * @param _receiver address or receiver
     * @param _feeDenominator value of fee Denominator
     */
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeDenominator
    ) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeDenominator);
    }

    /**
     * Reset token royalty information
     * @param _tokenId id of nft item
     */
    function setTokenRoyalty(uint256 _tokenId) external onlyOwner {
        _resetTokenRoyalty(_tokenId);
    }
}
