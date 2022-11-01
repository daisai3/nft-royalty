// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Ownable.sol";
import "./lib/IERC20.sol";
import "./lib/IERC721.sol";
import "./lib/IERC2981.sol";
import "./lib/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    // Structs
    struct Listing {
        uint256 price;
        address seller;
    }

    // Events
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 listedTimestamp
    );

    event ItemCancelled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 cancelledTimestamp
    );

    event ItemBought(
        address indexed buyer,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 purchasedTimestamp
    );

    // Modifiers
    modifier notListed(
        address NFTAddress,
        uint256 tokenId,
        address owner
    ) {
        require(
            listings[NFTAddress][tokenId].seller == address(0),
            "Error: already listed"
        );
        _;
    }

    modifier isNFTOwner(
        address NFTAddress,
        uint256 tokenId,
        address spender
    ) {
        require(
            IERC721(NFTAddress).ownerOf(tokenId) == msg.sender,
            "Error: not nft owner"
        );
        _;
    }

    modifier isListed(address NFTAddress, uint256 tokenId) {
        require(
            listings[NFTAddress][tokenId].seller != address(0),
            "Error: not listed"
        );
        _;
    }

    // An ERC-20 token that is accepted as payment in the marketplace (e.g. WAVAX)
    address tokenToPay;

    mapping(address => mapping(uint256 => Listing)) private listings;

    constructor(address _tokenToPay) {
        tokenToPay = _tokenToPay;
    }

    function listItem(
        address NFTAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(NFTAddress, tokenId, msg.sender)
        isNFTOwner(NFTAddress, tokenId, msg.sender)
    {
        require(price > 0, "Price must be above zero");
        require(
            IERC721(NFTAddress).getApproved(tokenId) == address(this),
            "Not approved for marketplace"
        );
        listings[NFTAddress][tokenId] = Listing(price, msg.sender);

        // emit ItemListed event for off-chain indexing and query
        emit ItemListed(
            msg.sender,
            NFTAddress,
            tokenId,
            price,
            block.timestamp
        );
    }

    function cancelListing(address NFTAddress, uint256 tokenId)
        external
        isNFTOwner(NFTAddress, tokenId, msg.sender)
        isListed(NFTAddress, tokenId)
    {
        delete (listings[NFTAddress][tokenId]);

        // emit ItemCancelled event for off-chain indexing and query
        emit ItemCancelled(msg.sender, NFTAddress, tokenId, block.timestamp);
    }

    /// @dev Need to add nonReentrant modifier because ERC20(WAVAX) token transfer(line#131) is done before storage update(line#136).
    /// So users can try to buy NFT time again before the previous tx is completed because `isListed` modifier does not block the second tx.
    /// The another best approach is to move line#138 to line#132 to update storage variable before token transfer.
    function buyItem(address NFTAddress, uint256 tokenId)
        external
        isListed(NFTAddress, tokenId)
        nonReentrant
    {
        Listing memory listedItem = listings[NFTAddress][tokenId];

        // implement royalty feature
        uint256 royaltiesAmount = 0;
        if (
            IERC2981(NFTAddress).supportsInterface(type(IERC2981).interfaceId)
        ) {
            address royaltiesReceiver;
            (royaltiesReceiver, royaltiesAmount) = IERC2981(NFTAddress)
                .royaltyInfo(tokenId, listedItem.price);
            if (royaltiesAmount > 0) {
                IERC20(tokenToPay).transferFrom(
                    msg.sender,
                    royaltiesReceiver,
                    royaltiesAmount
                );
            }
        }

        IERC20(tokenToPay).transferFrom(
            msg.sender,
            listedItem.seller,
            listedItem.price - royaltiesAmount
        );
        delete (listings[NFTAddress][tokenId]);
        IERC721(NFTAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );

        // emit ItemBought event for off-chain indexing and query
        emit ItemBought(
            msg.sender,
            listedItem.seller,
            NFTAddress,
            tokenId,
            listedItem.price,
            block.timestamp
        );
    }

    function updateListing(
        address NFTAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(NFTAddress, tokenId)
        isNFTOwner(NFTAddress, tokenId, msg.sender)
    {
        require(newPrice > 0, "Price must be above zero");
        listings[NFTAddress][tokenId].price = newPrice;
    }

    function getListing(address NFTAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[NFTAddress][tokenId];
    }
}
