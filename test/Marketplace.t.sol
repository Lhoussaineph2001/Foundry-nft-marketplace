//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {Test , console} from 'forge-std/Test.sol';
import {Vm} from 'forge-std/Vm.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFT_Marketplace} from '../src/NFT_Marketplace.sol';
import {DeployNFT} from '../script/NFT.s.sol';
import {DeployMarketplace} from '../script/Marketplace.s.sol';
import {NFT} from '../src/NFT.sol';


/**
 * @title Test NFT_MarketPlace
 * @author Lhoussaine Ait Aissa
 * @notice This contract is for testing the NFT_Marketplace contract
 */
contract testNFT_MarketPlace is Test {

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  STATE VARIABLES //////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    NFT_Marketplace marketplace;
    DeployMarketplace deployer;
    DeployNFT deployerNFT;

    NFT nft ; 
    address private seller = makeAddr("Seller");
    address private buyer = makeAddr("buyer");
    address private owner;
    string public tokenURI = "This is the URI token";
    string public tokenURI2 = "This is the URI token2";
    uint public tokenId;
    uint public tokenId2;
    uint256 public listingPrice = 0.001 ether; // the amont for listing a token
    uint256 constant public BALANCE = 100 ether; // the amont for listing a token

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  EVENTS        ////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    event Offered(uint  ItemId , address indexed nft , uint  tokenId , uint price , bool listed ,  address indexed seller);
    event Bought(uint  ItemId , address indexed nft , uint  tokenId ,uint price , address indexed seller ,  address indexed buyer );
    event UpdateItem(uint indexed ItemId, bool _listed);
    event reSell(uint indexed ItemId, uint256 price);


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  SETUP         ////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    function setUp() external {

        // vm.startPrank(owner); // owner of marketplace
        deployerNFT = new DeployNFT();
        deployer = new DeployMarketplace();
        // nft = new NFT();
        nft = deployerNFT.run();
        marketplace = deployer.run();
        
        // vm.stopPrank();
        // Give the seller some ether to pay for the listing
        vm.deal(seller,BALANCE);
        // Give the buyer some ether to pay for the listing
        vm.deal(buyer,BALANCE);

        // set Owner

        owner = marketplace.getOwner();

        // mint NFTs
        vm.startPrank(seller);
        tokenId = nft.mint(tokenURI);
        tokenId2 = nft.mint(tokenURI2);
        vm.stopPrank();



    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  MODIFIERS      ///////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    modifier addItem {

        vm.startPrank(seller);
        nft.setApprovalForAll(address(marketplace), true);
        uint itemId = marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId, 10);
        vm.stopPrank();
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  ERRORS         ///////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // PricemustbeAboveZero Error

    // In addItem
    function test_PricemustbeAboveZeroERRORINAddItem() external {

        vm.prank(seller);
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__PricemustbeAboveZero.selector);
        marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId, 0);

    }

    // In resell
    function test_PricemustbeAboveZeroERRORinResell() external addItem{

        console.log(address(this));
        vm.prank(seller);
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__PricemustbeAboveZero.selector);
        marketplace.resell(1,0);

    }


    // LessThenListedPrice
    function test_LessThanListedPriceERROR() external {

        vm.prank(seller);
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__LessThanListedPrice.selector);
        marketplace.addItem(IERC721(nft), tokenId, 10);
    }

    // LessThanNFTPrice

    function test_LessThanNFTPriceERROR() external addItem {

        vm.prank(buyer);

        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__LessThanNFTPrice.selector);
        marketplace.buyNFT(1);
    }

    // NFT_Marketplace__NFTNotListed

    function test__NFTNotListedERROR() external addItem{


        vm.prank(seller);
        marketplace.UpdateListed(1,false);


        vm.prank(buyer);
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__NFTNotListed.selector);
        marketplace.buyNFT{value : 10}(1);

    }


    // NFT_Marketplace__NotTheSeller

    function test_NotTheSellerERROR() external addItem{

        vm.prank(address(0x12));
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__NotTheSeller.selector);
        marketplace.UpdateListed(1,false);
    }

    function test_NotTheSellerERRORInResell() external addItem{

        
        vm.prank(address(0x12));
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__NotTheSeller.selector);
        marketplace.resell(1,10);
    }


    // NFT_Marketplace__NotTheOwner

    function test_NotTheOwnerERROR() external {

        vm.prank(address(0x12));
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__NotTheOwner.selector);
        marketplace.updateListedPrice(1);
    }
    
    function test_NotTheOwnerERRORInaddItem() external {

        vm.prank(buyer);
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__NotTheOwner.selector);
        marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId, 10);

    }


    // NFT_Marketplace__ItemDoesNotExist

    function test_ItemDoesNotExistERROR() external addItem{

        vm.prank(seller);
        vm.expectRevert(NFT_Marketplace.NFT_Marketplace__ItemDoesNotExist.selector);
        marketplace.UpdateListed(2,true);
    }


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  EVENTS       ////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Offered Event

    function test_OfferedEVENT() external {

        vm.startPrank(seller);

        nft.setApprovalForAll(address(marketplace), true);
        vm.expectEmit(true,true,true ,false);
        emit Offered(1 ,address(nft),tokenId ,10,true,seller);
        uint itemId = marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId, 10);
        vm.stopPrank();
    }

    // Bought Event

    function test_BoughtEVENT() external addItem{

        vm.startPrank(buyer);
            
        // Record all emitted logs
        vm.recordLogs();

        marketplace.buyNFT{value: 10}(1);

        // Retrieve recorded logs
        Vm.Log[] memory logs = vm.getRecordedLogs();
        vm.stopPrank();


        console.log(logs.length);
        // Find the `Bought` event log
        bool foundBoughtEvent = false;

    for (uint256 i = 0; i < logs.length; i++) {
        Vm.Log memory log = logs[i];

        console.log(log.topics[0] == keccak256("Bought(uint256,address,uint256,uint256,address,address)"));
        // Check if the log matches the `Bought` event signature
        if (log.topics[0] == keccak256("Bought(uint256,address,uint256,uint256,address,address)")) {
       
            console.log("Found Bought event");

            console.log("Log Data Length: %d", log.data.length);
            console.logBytes(log.data);
            

            // Decode indexed parameters
            address _nft = address(uint160(uint256(log.topics[1])));
            address _seller = address(uint160(uint256(log.topics[2])));
            address _buyer = address(uint160(uint256(log.topics[3])));

            // Decode the event data
            (uint256 itemId,uint256 _tokenId, uint256 price) =
                abi.decode(log.data, (uint256, uint256, uint256));

            // Assert the event parameters
            assertEq(itemId, 1, "Incorrect itemId");
            assertEq(_nft, address(nft), "Incorrect NFT address");
            assertEq(_tokenId, tokenId, "Incorrect tokenId");
            assertEq(price, 10, "Incorrect price");
            assertEq(_seller, seller, "Incorrect seller");
            assertEq(_buyer, buyer, "Incorrect buyer");

            foundBoughtEvent = true;
        }
    }

    // Ensure the `Bought` event was found
    assert(foundBoughtEvent);

    }

    // UpdateListed Event

    function test_UpdateListedEVENT() external addItem {

        vm.startPrank(seller);
        vm.expectEmit(true,true,true,false);
        emit UpdateItem(1,true);
        marketplace.UpdateListed(1,true);
        vm.stopPrank();

    }


    /// Resell Event

    function test_ResellEVENT() external addItem {

        vm.startPrank(seller);

        vm.expectEmit(true,true,true,false);
        emit reSell(1,10);
        marketplace.resell(1,10);
        vm.stopPrank();

    }







    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  FUNCTIONS     ////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Constructor

    function test_Owner() external  {

       assert(marketplace.getOwner() == owner);
    }

    // Add Item

    function test_AddItem() external {

        vm.startPrank(seller);
        nft.setApprovalForAll(address(marketplace), true);
        uint itemId = marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId, 10);
        vm.stopPrank();

        assert(itemId == 1);
    }

    // Update Listed Price

    function test_UpdateListedPrice() external {

        vm.prank(owner);
        marketplace.updateListedPrice(100);
        assert(marketplace.getListedPrice() == 100);
    }

    // Update Buy Fee

    function test_UpdateBuyFee() external {

        vm.prank(owner);
        marketplace.updateBuyfee(3);

        assert(marketplace.buyFee() == 3);
    }


    // Buy NFT 

    function test_BuyNFT() external addItem{

        vm.startPrank(buyer);
        marketplace.buyNFT{value: 10}(1);
        vm.stopPrank();

        address expectedSeller = marketplace.getListedItemForId(1).seller;
        assert(expectedSeller == buyer);
    }


    // Update Listed

    function test_UpdateListed() external addItem{

        vm.startPrank(seller);
        marketplace.UpdateListed(1,false);
        vm.stopPrank();

        bool expected = marketplace.getListedItemForId(1).listed;

        assert(expected == false);
    }

    // Resell NFT

    function test_ResellNFT() external addItem{

        vm.startPrank(seller);
        marketplace.resell(1,7);
        vm.stopPrank();

        uint expecteddPrice = marketplace.getListedItemForId(1).price;

        console.log(expecteddPrice);

        assert(expecteddPrice == 7); 
    }


    // Get latest Listed Items

    function test_GetLatestListedItems() external addItem{

        vm.startPrank(seller);
        marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId2, 9);
        vm.stopPrank();

        uint expected = marketplace.getlatestListedItemId();

        assert(expected == 2);

    }

    // Get Listed Items for Id

    function test_GetListedItemForId() external addItem{

        vm.startPrank(seller);
        marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId2, 8);
        vm.stopPrank();

        NFT_Marketplace.ListedItem memory expected = marketplace.getListedItemForId(1);

        assert(expected.price == 10);
        assert(expected.seller == seller);
        assert(expected.listed == true);
        assert(expected.ItemId == 1);
        assert(expected.NFT == IERC721(nft));
        assert(expected.tokenId == tokenId);

    }


    // GET All NFT For Collection

    function test_GetAllNFTsForCollection() external addItem{

        vm.startPrank(seller);
        marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId2, 7);
        vm.stopPrank();

        NFT_Marketplace.ListedItem [] memory expected = marketplace.getAllNFTsForCollection(IERC721(nft));

        assert(expected[0].price == 10);
        assert(expected[0].seller == seller);
        assert(expected[0].listed == true);
        assert(expected[0].ItemId == 1);
        assert(expected[0].NFT == IERC721(nft));
        assert(expected[0].tokenId == tokenId);
        assert(expected[1].price == 7);
        assert(expected[1].seller == seller);
        assert(expected[1].listed == true);
        assert(expected[1].ItemId == 2);
        assert(expected[1].NFT == IERC721(nft));
        assert(expected[1].tokenId == tokenId2);

    }
    
    // GET All NFT Listed

    function test_GetAllNFTsForListedItems() external addItem{

        vm.startPrank(seller);
        marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId2, 7);
        marketplace.UpdateListed(1,false);
        vm.stopPrank();


        NFT_Marketplace.ListedItem [] memory expected = marketplace.getAllItemsLsited();

        assert(expected[0].price == 7);
        assert(expected[0].seller == seller);
        assert(expected[0].listed == true);
        assert(expected[0].ItemId == 2);
        assert(expected[0].NFT == IERC721(nft));
        assert(expected[0].tokenId == tokenId2);

    }
    
    
    // GET All NFT For Seller

    function test_GetAllNFTsForSeller() external addItem{

        vm.startPrank(seller);
        marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId2, 17);
        NFT_Marketplace.ListedItem [] memory expected = marketplace.getMyNFT();
        vm.stopPrank();


        assert(expected[0].price == 10);
        assert(expected[0].seller == seller);
        assert(expected[0].listed == true);
        assert(expected[0].ItemId == 1);
        assert(expected[0].NFT == IERC721(nft));
        assert(expected[0].tokenId == tokenId);
        assert(expected[1].price == 17);
        assert(expected[1].seller == seller);
        assert(expected[1].listed == true);
        assert(expected[1].ItemId == 2);
        assert(expected[1].NFT == IERC721(nft));
        assert(expected[1].tokenId == tokenId2);

    }

    // Calculate Buy Fee

    function test_getbuyFee() external {

        uint Actually = marketplace.getbuyfee(10);

        uint Buyfee = marketplace.buyFee();
        uint PRESIGEN = marketplace.PRESIGEN();

        uint expected = (10*Buyfee)/PRESIGEN;

        assert(Actually == expected);


    }

    // Get Latest Item

    function test_getlatestItemId() external addItem {

        vm.startPrank(seller);
        marketplace.addItem{value: listingPrice}(IERC721(nft), tokenId2, 8);
        vm.stopPrank();

        uint LastId = marketplace.getlatestItemId();

        assert(LastId == 2);

    }


}
