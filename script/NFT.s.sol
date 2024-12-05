// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFT} from "../src/NFT.sol";

/**
 * @title Script to deploy NFT
 * @author Lhoussaine Ait Aissa
 * @notice This script is used to deploy the NFT contract
 */

contract DeployNFT is Script {

    NFT nft;
    function run() external returns (NFT) { 

        uint privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        nft = new NFT();
        vm.stopBroadcast();

        return nft;
        
    }
}