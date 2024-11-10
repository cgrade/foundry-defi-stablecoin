// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecntralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

/**
 * @title DSCEngineTest
 * @author Abraham Elijah
 * @notice This contract contains unit tests for the DSCEngine contract.
 * @dev It tests various functionalities including collateral deposit, price feed retrieval, and error handling.
 */
contract DSCEngineTest is Test {
    DeployDSC deployer; // Instance of the DeployDSC contract
    DecentralizedStableCoin dsc; // Instance of the DecentralizedStableCoin contract
    DSCEngine engine; // Instance of the DSCEngine contract
    HelperConfig config; // Instance of the HelperConfig contract
    address weth; // Address of the WETH token
    address wbtc; // Address of the WBTC token
    address ethUsdPriceFeed; // Address of the ETH USD price feed
    address btcUsdPriceFeed; // Address of the BTC USD price feed

    address public USER = makeAddr("user"); // User address for testing
    uint256 public constant AMOUNT_COLLATERAL = 10e18; // Amount of collateral for testing
    uint256 public constant STARTING_BALANCE = 10e18; // Starting balance for the user

    function setUp() public {
        deployer = new DeployDSC(); // Deploy the DSC contracts
        (dsc, engine, config) = deployer.run(); // Retrieve deployed contracts
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig(); // Get network config
        ERC20Mock(weth).mint(USER, STARTING_BALANCE); // Mint starting balance for the user
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TEST
    //////////////////////////////////////////////////////////////*/
    address[] public tokenAddresses; // Array to hold token addresses
    address[] public priceFeedAddresses; // Array to hold price feed addresses

    /**
     * @notice Tests that the DSCEngine constructor reverts if token and price feed lengths do not match.
     */
    function testRevertsIfTokenLengthDoesNotMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        // tokenAddresses.push(wbtc); // Uncomment to test with both tokens
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustMatch.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /*//////////////////////////////////////////////////////////////
                           PRICE FEED TEST
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests the USD value retrieval for a given amount of WETH.
     */
    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18; // Amount of ETH to convert
        uint256 expectedUsdValue = 30000e18; // Expected USD value
        uint256 actualUsdValue = engine.getUsdValue(weth, ethAmount); // Get actual USD value
        assertEq(actualUsdValue, expectedUsdValue); // Assert equality
    }

    /**
     * @notice Tests the token amount retrieval from a specified USD amount.
     */
    function testgetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether; // Amount in USD
        uint256 expectedTokenAmount = 0.05 ether; // Expected token amount
        uint256 actualTokenAmount = engine.getTokenAmountFromUsd(weth, usdAmount); // Get actual token amount
        assertEq(actualTokenAmount, expectedTokenAmount); // Assert equality
    }

    /*//////////////////////////////////////////////////////////////
                         DEPOSIT COLLATERAL TEST
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that depositing zero collateral reverts.
     */
    function testRevertsIfColateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL); // Approve collateral

        vm.expectRevert(DSCEngine.DSCEngine__NeedsToBeMoreThanZero.selector);
        engine.depositCollateral(weth, 0); // Attempt to deposit zero collateral
        vm.stopPrank();
    }

    /**
     * @notice Tests that depositing an unsupported token reverts.
     */
    function testIsUnAllowedToken() public {
        ERC20Mock testToken = new ERC20Mock(); // Create a new mock token
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotSupported.selector);
        engine.depositCollateral(address(testToken), 10e18); // Attempt to deposit unsupported token
    }

    /**
     * @notice Tests that depositing an unapproved collateral token reverts.
     */
    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock(); // Create a new mock token
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotSupported.selector);
        engine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL); // Attempt to deposit unapproved collateral
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL); // Approve collateral
        engine.depositCollateral(weth, AMOUNT_COLLATERAL); // Deposit collateral
        _;
    }

    /**
     * @notice Tests that account information can be retrieved after depositing collateral.
     */
    function testCanDepoistCollateralAngGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER); // Get account info
        uint256 expectedTotalDscMinted = 0; // Expected total DSC minted
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd); // Expected deposit amount
        assertEq(totalDscMinted, expectedTotalDscMinted); // Assert equality
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount); // Assert equality
    }

    /**
     * @notice Tests that collateral deposit works correctly.
     */
    function testDepositCollateral() public depositedCollateral {
        uint256 expectedTotalDscMinted = 0; // Expected total DSC minted
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, AMOUNT_COLLATERAL); // Expected deposit amount
        uint256 expectedCollateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL); // Expected collateral value in USD

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER); // Get account info
        assertEq(totalDscMinted, expectedTotalDscMinted); // Assert equality
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount); // Assert equality
        assertEq(collateralValueInUsd, expectedCollateralValueInUsd); // Assert equality
    }
}
