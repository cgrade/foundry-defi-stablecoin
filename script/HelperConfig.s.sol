// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.t.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

/**
 * @title HelperConfig
 * @author Abraham Elijah
 * @notice This contract provides configuration for deploying the Decentralized Stable Coin (DSC) and its associated DSCEngine.
 * @dev It retrieves network-specific configurations, including price feeds and token addresses.
 */
contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUsdPriceFeed; // Address of the WETH USD price feed
        address wbtcUsdPriceFeed; // Address of the WBTC USD price feed
        address weth; // Address of the WETH token
        address wbtc; // Address of the WBTC token
        uint256 deployerKey; // Private key of the deployer
    }

    // Constants for WETH and WBTC
    uint8 public constant WETH_DECIMALS = 8; // Decimals for WETH
    uint8 public constant WBTC_DECIMALS = 8; // Decimals for WBTC
    int256 public constant WETH_USD_PRICE = 2000 * 10 ** 8; // Mock price for WETH
    int256 public constant WBTC_USD_PRICE = 60000 * 10 ** 8; // Mock price for WBTC
    uint256 public constant ANVIL_DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Deployer key for Anvil

    NetworkConfig public activeNetworkConfig; // Active network configuration

    constructor() {
        // Set the active network configuration based on the chain ID
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    /**
     * @notice Retrieves the configuration for the Sepolia Ethereum network.
     * @return NetworkConfig The network configuration for Sepolia.
     */
    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    /**
     * @notice Retrieves or creates the configuration for the Anvil network.
     * @return NetworkConfig The network configuration for Anvil.
     */
    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // Check to see if we have an existing config
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // Create a new config
        vm.startBroadcast();
        // WETH mock price feed
        MockV3Aggregator wethUsdPriceFeed = new MockV3Aggregator(WETH_DECIMALS, WETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock();

        // WBTC mock price feed
        MockV3Aggregator wbtcUsdPriceFeed = new MockV3Aggregator(WBTC_DECIMALS, WBTC_USD_PRICE);
        ERC20Mock wbtcMock = new ERC20Mock();
        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeed: address(wethUsdPriceFeed),
            wbtcUsdPriceFeed: address(wbtcUsdPriceFeed),
            weth: address(wethMock),
            wbtc: address(wbtcMock),
            deployerKey: ANVIL_DEPLOYER_KEY
        });
    }
}
