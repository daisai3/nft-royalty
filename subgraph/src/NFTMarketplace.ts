import { Address, BigDecimal, BigInt } from "@graphprotocol/graph-ts";
import {
  ItemListed,
  ItemBought,
  ItemCancelled,
} from "../generated/NFTMarketplace/NFTMarketplace";
import {
  Collection,
  NFT,
  ItemListedEvent,
  ItemCancelledEvent,
  ItemBoughtEvent,
  User,
} from "../generated/schema";

// handle ItemListed Events
export function handleItemListed(event: ItemListed): void {
  let sellerAddr = event.params.seller.toString();
  let nftCollectionAddr = event.params.nftAddress.toString();
  let tokenId = event.params.tokenId;
  let price = event.params.price;
  let listedTimestamp = event.params.listedTimestamp;

  // User schema handling
  let user = User.load(sellerAddr);
  if (!user) {
    user = new User(sellerAddr);
    user.numberTokensListed = BigInt.zero();
    user.numberTokensBought = BigInt.zero();
  }
  user.numberTokensListed = user.numberTokensListed.plus(BigInt.fromI32(1));
  user.save();

  // Collection schema handling
  let collection = Collection.load(nftCollectionAddr);
  if (!collection) {
    collection = new Collection(nftCollectionAddr);
  }
  collection.save();

  // NFT schema handling
  let nft = NFT.load(nftCollectionAddr + tokenId.toString());
  if (!nft) {
    nft = new NFT(nftCollectionAddr + tokenId.toString());
    nft.collection = nftCollectionAddr;
    nft.tokenId = tokenId;
  }
  nft.currentSeller = sellerAddr;
  nft.listedPrice = BigDecimal.fromString(price.toString());
  nft.lastSoldPrice = BigDecimal.zero();
  nft.lastListedTimestamp = listedTimestamp;
  nft.lastSoldTimestamp = BigInt.zero();
  nft.save();

  // ItemListedEvent schema handling
  let itemListedEvent = new ItemListedEvent(event.transaction.hash.toHex());
  itemListedEvent.collection = nftCollectionAddr;
  itemListedEvent.tokenId = tokenId;
  itemListedEvent.seller = sellerAddr;
  itemListedEvent.price = BigDecimal.fromString(price.toString());
  itemListedEvent.timestamp = listedTimestamp;
  itemListedEvent.save();
}

// handle ItemBought Events
export function handleItemBought(event: ItemBought): void {
  let sellerAddr = event.params.seller.toString();
  let buyerAddr = event.params.buyer.toString();
  let nftCollectionAddr = event.params.nftAddress.toString();
  let tokenId = event.params.tokenId;
  let price = event.params.price;
  let purchasedTimestamp = event.params.purchasedTimestamp;

  // User schema handling
  let user = User.load(sellerAddr);
  if (!user) {
    user = new User(sellerAddr);
    user.numberTokensListed = BigInt.zero();
    user.numberTokensBought = BigInt.zero();
  }
  user.numberTokensBought = user.numberTokensBought.plus(BigInt.fromI32(1));
  user.save();

  // Collection schema handling
  let collection = Collection.load(nftCollectionAddr);
  if (!collection) {
    collection = new Collection(nftCollectionAddr);
  }
  collection.save();

  // NFT schema handling
  let nft = NFT.load(nftCollectionAddr + tokenId.toString());
  if (!nft) {
    nft = new NFT(nftCollectionAddr + tokenId.toString());
    nft.collection = nftCollectionAddr;
    nft.tokenId = tokenId;
  }
  nft.currentSeller = Address.zero().toString();
  nft.listedPrice = BigDecimal.zero();
  nft.lastSoldPrice = BigDecimal.fromString(price.toString());
  nft.lastListedTimestamp = BigInt.zero();
  nft.lastSoldTimestamp = purchasedTimestamp;
  nft.save();

  // ItemBoughtEvent schema handling
  let itemBoughtEvent = new ItemBoughtEvent(event.transaction.hash.toHex());
  itemBoughtEvent.collection = nftCollectionAddr;
  itemBoughtEvent.tokenId = tokenId;
  itemBoughtEvent.seller = sellerAddr;
  itemBoughtEvent.buyer = buyerAddr;
  itemBoughtEvent.price = BigDecimal.fromString(price.toString());
  itemBoughtEvent.timestamp = purchasedTimestamp;
  itemBoughtEvent.save();
}

// handle ItemCancelled Events
export function handleItemCancelled(event: ItemCancelled): void {
  let sellerAddr = event.params.seller.toString();
  let nftCollectionAddr = event.params.nftAddress.toString();
  let tokenId = event.params.tokenId;
  let cancelledTimestamp = event.params.cancelledTimestamp;

  // User schema handling
  let user = User.load(sellerAddr);
  if (!user) {
    user = new User(sellerAddr);
    user.numberTokensListed = BigInt.zero();
    user.numberTokensBought = BigInt.zero();
  }
  user.numberTokensListed = user.numberTokensListed.minus(BigInt.fromI32(1));
  user.save();

  // Collection schema handling
  let collection = Collection.load(nftCollectionAddr);
  if (!collection) {
    collection = new Collection(nftCollectionAddr);
  }
  collection.save();

  // NFT schema handling
  let nft = NFT.load(nftCollectionAddr + tokenId.toString());
  if (!nft) {
    nft = new NFT(nftCollectionAddr + tokenId.toString());
    nft.collection = nftCollectionAddr;
    nft.tokenId = tokenId;
    nft.lastSoldPrice = BigDecimal.zero();
  }
  nft.currentSeller = Address.zero().toString();
  nft.listedPrice = BigDecimal.zero();
  nft.lastListedTimestamp = BigInt.zero();
  nft.lastSoldTimestamp = BigInt.zero();
  nft.save();

  // ItemCancelledEvent schema handling
  let itemCancelledEvent = new ItemCancelledEvent(
    event.transaction.hash.toHex()
  );
  itemCancelledEvent.collection = nftCollectionAddr;
  itemCancelledEvent.tokenId = tokenId;
  itemCancelledEvent.seller = sellerAddr;
  itemCancelledEvent.timestamp = cancelledTimestamp;
  itemCancelledEvent.save();
}
