// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



/**
 * @title NFT Marketplace
 * @dev This contract enables users to list, buy, and sell NFTs on the Ethereum blockchain.
 * 
 * Features:
 * - Supports ERC721 tokens.
 * - Includes custom errors to save gas.
 * - Implements fees for listing and purchasing.
 *
 * @author Lhoussaine Ait Aissa
 * @notice This contract is designed for educational and practical use cases.
 */

 // ERC721Receiver Interface
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


contract NFT_Marketplace{

    // implement this for holding NFT 

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external  returns (bytes4) {
        // Handle the receipt of the token
        // You can add custom logic here, such as updating internal state
        return this.onERC721Received.selector; // Return the correct selector to indicate success
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  CUSTEM ERRORS    /////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        error NFT_Marketplace__PricemustbeAboveZero();
        error NFT_Marketplace__LessThanListedPrice();
        error NFT_Marketplace__LessThanNFTPrice();
        error NFT_Marketplace__NFTNotListed();
        error NFT_Marketplace__NotTheSeller();
        error NFT_Marketplace__NotTheOwner();
        error NFT_Marketplace__ItemDoesNotExist();


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  VARIABLE STATES     /////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Counters for item IDs and token IDs

    using Counters for Counters.Counter;

    Counters.Counter private _itemIds;
    Counters.Counter private _itemlisted;


    address  payable owner;
    uint256 public listingPrice = 0.001 ether; // the amont for listing a token
    uint256 public buyFee = 2 ; // 2% fee for buying a token
    uint256 constant public PRESIGEN = 100;


    // Struct to represent a listed item
    struct ListedItem {

        uint ItemId;
        IERC721 NFT;
        uint256 tokenId;
        address payable seller;  // Current seller, who is listing the NFT for sale
        uint256 price;
        bool listed;

    }


    // Mapping to store listed items
    mapping(uint256 => ListedItem) public idToListedItem;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  EVENTS     ///////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Events to log item listings and purchases
    event Offered(uint  ItemId , address indexed nft , uint  tokenId , uint price , bool listed ,  address indexed seller);
    event Bought(uint  ItemId , address indexed nft , uint  tokenId ,uint price , address indexed seller ,  address indexed buyer );
    event UpdateItem(uint indexed ItemId, bool _listed);
    event reSell(uint indexed ItemId, uint256 price);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  MODIFIERS     ///////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Modifier to check if the caller is the owner
    modifier  OnlyOwner  {

        if (owner != msg.sender) {

            revert NFT_Marketplace__NotTheOwner();
        }
        _;
    }
    
    modifier ValidItem(uint256 _itemId) {

        if(_itemId <=  0 || _itemId > _itemIds.current()) {

            revert NFT_Marketplace__ItemDoesNotExist();
        }
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  FUNCTIONS     ////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Constructor to initialize the contract
    constructor() {


        owner = payable(msg.sender);
    }




    /**
     * @notice Tis function allow the owner to update the listing price
     * @param _listingPrice - The price at which the item is listed
     */

    function updateListedPrice(uint256 _listingPrice) external OnlyOwner {

        listingPrice = _listingPrice;
    }
    
    /**
     * @notice Tis function allow the owner to update the fee for buying a token
     * @param _Newfee - The new fee for buying a token
     */

    function updateBuyfee(uint256 _Newfee) public OnlyOwner {

        buyFee = _Newfee;
    }


    /**
     * @dev Function to create a new listed item
     * @param _NFT - The address of the NFT contract
     * @param _tokenId - The ID of the NFT token
     * @param price - The price at which the item is listed
     * @return The ID of the newly created listed item
     */

    function addItem(IERC721 _NFT,uint _tokenId , uint256 price) public payable returns (uint) {

        if (msg.value != listingPrice) {

            revert NFT_Marketplace__LessThanListedPrice();
        }

        if (price <= 0 ){

            revert NFT_Marketplace__PricemustbeAboveZero();
        }

        if (_NFT.ownerOf(_tokenId) != msg.sender){
            
            revert NFT_Marketplace__NotTheOwner();
        }

        // Increment the item ID counter
        _itemIds.increment();

        // Increment the listed item counter
        _itemlisted.increment();

        // Create a new listed item
       createListedItem(_itemIds.current() , _NFT,_tokenId,price);



       // using the approve function to approve the contract to transfer the NFT on behalf of the owner
       _NFT.safeTransferFrom(msg.sender,address(this),_tokenId); 

       // emit an event to log the listing of the item
       emit Offered(_itemIds.current() , address(_NFT) , _tokenId , price , true , msg.sender);

        // Return the item ID
        return _itemIds.current();

    }


    /**
     * 
     * @param _itemId - The ID of the listed item
     * @param _NFT - The instance of the NFT contract
     * @param _tokenId - The ID of the NFT token
     * @param price - The price at which the item is listed
     */

    function createListedItem(uint _itemId ,IERC721 _NFT , uint _tokenId, uint256 price) private {


        idToListedItem[_itemId] = ListedItem(

            _itemId,
            _NFT, // instance of the NFT contract
            _tokenId, // ID of the NFT token
            payable(msg.sender), // seller
            price,
            true // listed by default

        );

    }

    /**
     * @notice This function allow user to buy an NFT
     * @param _itemId - The ID of the listed item
     * 
     */
    function buyNFT(uint256 _itemId) public payable ValidItem(_itemId){

        ListedItem storage Item = idToListedItem[_itemId];
        
        // CHECKS


        if (msg.value != Item.price) {

            revert NFT_Marketplace__LessThanNFTPrice();
        }

        console.log(Item.listed);
        if (!Item.listed) {

            revert NFT_Marketplace__NFTNotListed();
        }

        // EFFECTS
        address payable seller = Item.seller;

        IERC721 NFT = Item.NFT;
        uint tokenId = Item.tokenId;

        // INTERACTIONS
        // transfer the NFT to the buyer
        NFT.safeTransferFrom(address(this), msg.sender, tokenId); 
        
        // change the seller to the buyer
        idToListedItem[_itemId].seller = payable(msg.sender); 

        // listed by default
        
        // Calculate the fee and the seller amount
        uint fee =  getbuyfee(Item.price);  
        uint sellerAmount = Item.price - fee;

        
        // decrement the listed item counter
        _itemlisted.decrement();

        // transfer the fee to the owner
        payable(owner).transfer(fee); 

        
        // transfer the NFT price to seller
        payable(seller).transfer(sellerAmount); 

        // emit an event to log the purchase of the item
        emit Bought(Item.ItemId , address(NFT) , tokenId , Item.price ,seller, msg.sender);
        

    }


    /**
     * @notice This function allow user to update the listing of an NFT
     * @param _ItemId - The ID of the listed item
     * @param _listed - The new status of the listed item
     */

    function UpdateListed(uint _ItemId , bool _listed) external ValidItem(_ItemId) {

        ListedItem memory Item = idToListedItem[_ItemId];

        // Check if the caller is the seller of the item
        if (msg.sender != Item.seller) {

            revert NFT_Marketplace__NotTheSeller();
        }

        // Update the listed status of the item

        idToListedItem[_ItemId].listed = _listed;

        // if not listed then transfer the NFT back to the seller
        if(!_listed) {
            uint _tokenId = Item.tokenId;
            _itemlisted.decrement();

            console.log(_itemlisted.current());
            Item.NFT.safeTransferFrom(address(this),msg.sender,_tokenId); 

        }

        // Emit an event to log the update of the item
        emit UpdateItem(_ItemId , _listed);

    }

    /**
     * 
     * @param _itemId - The ID of the listed item
     * @param _price -The new price of the listed item
     * @return The ID of the update item
     */
    function resell(uint256 _itemId , uint256 _price) external ValidItem(_itemId) returns (uint) {

        ListedItem memory item = idToListedItem[_itemId];

        if (item.seller != msg.sender) {

            revert NFT_Marketplace__NotTheSeller();
        }

        if( _price <= 0 ) {

            revert NFT_Marketplace__PricemustbeAboveZero();
        }

        if (!item.listed) {
            
        // Increment the listed item counter
        _itemlisted.increment();

        }

        // set the new price
        idToListedItem[_itemId].price = _price;

        // emit an event for this update
        emit reSell(_itemId,_price);

        // retun The ID of the update Item
        return _itemId;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////// Getter Functions ///////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @return The address of the owner
     */

    function getOwner() public view returns (address) {
        return owner;
    }


    /**
     * @notice This function for get the listing price
     * @return The listing price
     */
    function getListedPrice() public view returns (uint256) {

        return listingPrice;
    }


    /**
     * @notice This function for get the latest item id
     * @return The latest item id
     */
    function getlatestItemId() public view returns (uint256) {

        return _itemIds.current();
    }
    
    /**
     * @notice This function for get the latest listed item 
     * @return The latest Listed item id
     */
    function getlatestListedItemId() public view returns (uint256) {


        return _itemlisted.current();
    }
    /**
     * 
     * @param _itemId - The ID of the listed item
     * @return The listed item
     */
    function getListedItemForId(uint256 _itemId) public view returns (ListedItem memory) {

        return idToListedItem[_itemId];

    }


    /**
     * @dev This function for get all listed items for a given NFT contract for sepicific collection
     * @param _NFT - The instance of the NFT contract
     * @return The listed items for the given NFT contract
     */

    function getAllNFTsForCollection( IERC721 _NFT) public view returns (ListedItem[] memory ) {

    
            // get latest id use 
            uint totalItems = getlatestItemId(); 

            console.log("totalItems : %s", totalItems);
            // counter
            uint Count = 0;

            // loop through all items
            for(uint i = 1 ; i <= totalItems ; i++ ) {


                ListedItem memory item = getListedItemForId(i);
                console.log("item.NFT : %s", address(item.NFT));

                if (item.NFT == _NFT) {

                    Count++;
                }
            }

            console.log("Count : %s", Count);
            // create a new array to store the listed items
            ListedItem[] memory Collection = new ListedItem[](Count);


            for(uint i = 0 ; i < totalItems; i++ ) {

                ListedItem memory Item = getListedItemForId(i+1);
                // check if the item is the same as the one we are looking for

                console.log("Item.NFT : %s", address(Item.NFT));    
                if (Item.NFT == _NFT) {

                    console.log("Item.NFT Add : %s", address(Item.NFT));
                    Collection[i] = Item;

                    console.log("Collection[i] : %s", Collection[i].ItemId);

                }
            }

            console.log("Collection[0] : %s", Collection[0].ItemId);
            console.log("Collection[1] : %s", Collection[1].ItemId);

            // console.log(Collection.lenght);

            // return the collection
            return Collection;

        }
        

    /**
     * @notice This function for get all listed items
     * @return The listed items
     */
    function getAllItemsLsited() external view returns(ListedItem [] memory) {

        uint totalItems = getlatestItemId(); // get latest id use

        uint Count = getlatestItemId(); // get latest id use
        console.log(Count);
        ListedItem[] memory Collection = new ListedItem[](Count);

        uint increment = 0;

        for(uint i = 0 ; i < totalItems; i++ ) {

            ListedItem memory Item = getListedItemForId(i+1);

            console.log(Item.ItemId);

            if (Item.listed == true) {


                Collection[increment] = Item;
                increment++;
            }
        }


        return Collection;

    
        
    }

    /**
     * @notice This function for get all listed items for the msg.sender
     * @return The listed items for the msg.sender
     */
    function getMyNFT() external view returns(ListedItem [] memory) {

        uint totalItems = getlatestItemId(); // get latest id use 

        uint Count = 0; // counter

        console.log(msg.sender);

        for(uint i = 0 ; i < totalItems ; i++ ) {


            ListedItem memory item = getListedItemForId(i+1);

        console.log(item.seller);

            if (item.seller == msg.sender) {

                Count++;
            }
        }

        console.log(Count);

        ListedItem[] memory Collection = new ListedItem[](Count);

        uint increment = 0 ;

        for(uint i = 0 ; i < totalItems; i++ ) {

            ListedItem memory Item = getListedItemForId(i+1);

            if (Item.seller == msg.sender) {

                console.log(increment);

                Collection[increment] = Item;
                increment++;
            }
        }


        return Collection;

    
    }


    /**
     * @notice This function for get the buy fee
     * @return The buy fee
     */
    function getbuyfee(uint price) public view returns(uint) {

        return (price * buyFee ) / PRESIGEN;
    }

}