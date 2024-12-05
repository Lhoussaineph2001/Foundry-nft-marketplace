// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFT_Marketplace} from "../src/NFT_Marketplace.sol";

/**
 * @title Script to deploy NFT_Marketplace
 * @author Lhoussaine Ait Aissa
 * @notice This script is used to deploy the NFT_Marketplace contract
 */

contract DeployMarketplace is Script {

    NFT_Marketplace marketplace;

    function run() external returns (NFT_Marketplace) {

        uint privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);
        marketplace = new NFT_Marketplace();
        vm.stopBroadcast();

        return marketplace;
        
    }
}