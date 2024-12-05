// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// // custom errors
// error NftMarketplace__PriceMustBeAboveZero();
// error NftMarketplace__NftNotApproved();
// error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
// error NftMarketplace__NotOwner();
// error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
// error NftMarketplace__SentLessThanListed(address nftAddress, uint256 tokenId);
// error NftMarketplace__NotEnoughProceeds();
// error NftMarketplace__WithdrawProceedsFailed();

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// contract NftMarketplace is ReentrancyGuard {
//   struct Listing {
//     uint256 price;
//     address seller;
//   }

//   // Mappings
//   mapping(address => mapping(uint256 => Listing)) private s_listings;
//   mapping(address => uint256) private s_proceeds;

//   // Events
//   event ItemListed(
//     address indexed seller,
//     address indexed nftAddress,
//     uint256 indexed tokenId,
//     uint256 price
//   );

//   event ItemBrought(
//     address indexed buyer,
//     address indexed nftAddress,
//     uint256 indexed tokenId,
//     uint256 price
//   );

//   event ItemCancelled(
//     address indexed seller,
//     address indexed nftAddress,
//     uint256 indexed tokenId
//   );

//   // Modifiers
//   modifier notListed(
//     address nftAddress,
//     uint256 tokenId,
//     address owner
//   ) {
//     Listing memory listing = s_listings[nftAddress][tokenId];
//     if (listing.price > 0) {
//       revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
//     }
//     _;
//   }

//   modifier isOwner(
//     address nftAddress,
//     uint256 tokenId,
//     address spender
//   ) {
//     if (spender != IERC721(nftAddress).ownerOf(tokenId)) {
//       revert NftMarketplace__NotOwner();
//     }
//     _;
//   }

//   modifier isListed(address nftAddress, uint256 tokenId) {
//     Listing memory listing = s_listings[nftAddress][tokenId];
//     if (listing.price <= 0) {
//       revert NftMarketplace__NotListed(nftAddress, tokenId);
//     }
//     _;
//   }

//   function listItem(
//     address nftAddress,
//     uint256 tokenId,
//     uint256 price
//   )
//     external
//     notListed(nftAddress, tokenId, msg.sender)
//     isOwner(nftAddress, tokenId, msg.sender)
//   {
//     if (price <= 0) {
//       revert NftMarketplace__PriceMustBeAboveZero();
//     }
//     IERC721 nft = IERC721(nftAddress);
//     if (nft.getApproved(tokenId) != address(this)) {
//       revert NftMarketplace__NftNotApproved();
//     }
//     s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
//     emit ItemListed(msg.sender, nftAddress, tokenId, price);
//   }

//   function buyItem(
//     address nftAddress,
//     uint256 tokenId
//   ) external payable nonReentrant isListed(nftAddress, tokenId) {
//     Listing memory listedItem = s_listings[nftAddress][tokenId];
//     if (msg.value < listedItem.price) {
//       revert NftMarketplace__SentLessThanListed(nftAddress, tokenId);
//     }
//     s_proceeds[listedItem.seller] += msg.value;
//     delete s_listings[nftAddress][tokenId];
//     IERC721(nftAddress).safeTransferFrom(
//       listedItem.seller,
//       msg.sender,
//       tokenId
//     );
//     emit ItemBrought(msg.sender, nftAddress, tokenId, listedItem.price);
//   }

//   function cancelListing(
//     address nftAddress,
//     uint256 tokenId
//   )
//     external
//     isOwner(nftAddress, tokenId, msg.sender)
//     isListed(nftAddress, tokenId)
//   {
//     delete (s_listings[nftAddress][tokenId]);
//     emit ItemCancelled(msg.sender, nftAddress, tokenId);
//   }

//   function updateListings(
//     address nftAddress,
//     uint256 tokenId,
//     uint256 newPrice
//   )
//     external
//     isListed(nftAddress, tokenId)
//     isOwner(nftAddress, tokenId, msg.sender)
//   {
//     s_listings[nftAddress][tokenId].price = newPrice;
//     emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
//   }

//   function withdrawProceeds() external payable {
//     uint256 proceeds = s_proceeds[msg.sender];
//     if (proceeds <= 0) {
//       revert NftMarketplace__NotEnoughProceeds();
//     }
//     s_proceeds[msg.sender] = 0;
//     (bool success, ) = msg.sender.call{value: proceeds}("");
//     if (!success) {
//       revert NftMarketplace__WithdrawProceedsFailed();
//     }
//   }

//   // Getter Functions
//   function getListing(
//     address nftAddress,
//     uint256 tokenId
//   ) external view returns (Listing memory) {
//     return s_listings[nftAddress][tokenId];
//   }

//   function getProceeds(address seller) external view returns (uint256) {
//     return s_proceeds[seller];
//   }
// }

// // Reeentratcy Attack
// // Oracle Attack