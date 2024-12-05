// SPDX-License_Identifier:MIT

pragma solidity ^0.8.20;

import {Test , console} from 'forge-std/Test.sol';
import {DeployNFT} from '../script/NFT.s.sol';
import {NFT} from '../src/NFT.sol';

/**
 * @title TEST NFT
 * @author Lhoussaine Ait Aissa
 * @notice This contract is for testing the NFT contract
 */
contract testNFT is Test {


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  STATE VARIABLES //////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    DeployNFT deployer;
    NFT public nft;
    string public tokenURI = "This is the URI token";

    address public minter = makeAddr("minter");

    function setUp() external {

        deployer = new DeployNFT();
        nft = deployer.run();
        
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////  MINT FUNCTION  //////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function test_mint() external  {

        vm.prank(minter);
        uint tokenId =  nft.mint(tokenURI);

        assertEq(tokenId , 1);
    }
}