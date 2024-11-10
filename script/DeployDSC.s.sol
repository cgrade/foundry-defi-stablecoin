// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecntralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * @title DeployDSC
 * @author Abraham Elijah
 * @notice This contract is responsible for deploying the Decentralized Stable Coin (DSC) and its associated DSCEngine.
 * @dev The deployment process involves setting up the necessary token addresses and price feed addresses.
 */
contract DeployDSC is Script {
    address[] public tokenAddresses; // Array to hold the addresses of collateral tokens
    address[] public priceFeedAddresses; // Array to hold the addresses of price feeds for the collateral tokens

    /**
     * @notice The main function to deploy the DSC and DSCEngine contracts.
     * @return dsc The deployed DecentralizedStableCoin contract.
     * @return engine The deployed DSCEngine contract.
     * @return config The HelperConfig instance used for deployment configuration.
     */
    function run() public returns (DecentralizedStableCoin dsc, DSCEngine engine, HelperConfig config) {
        // Create an instance of HelperConfig to retrieve network-specific configurations
        config = new HelperConfig();

        // Retrieve the price feed addresses and token addresses for WETH and WBTC, along with the deployer's private key
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            config.activeNetworkConfig();

        // Set the price feed and token addresses
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        tokenAddresses = [weth, wbtc];

        // Start broadcasting the deployment transaction
        vm.startBroadcast(deployerKey);
        
        // Deploy the Decentralized Stable Coin contract
        dsc = new DecentralizedStableCoin();
        
        // Deploy the DSCEngine contract with the token and price feed addresses
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        
        // Transfer ownership of the DSC contract to the DSCEngine contract
        dsc.transferOwnership(address(engine));
        
        // Stop broadcasting the deployment transaction
        vm.stopBroadcast();
        
        // Return the deployed contracts and configuration
        return (dsc, engine, config);
    }
}
