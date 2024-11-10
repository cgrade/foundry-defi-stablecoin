// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volatility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.19;

/*//////////////////////////////////////////////////////////////
                                                                    IMPORT
                                    //////////////////////////////////////////////////////////////*/

import {DecentralizedStableCoin} from "./DecntralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";

/*//////////////////////////////////////////////////////////////
                                                                    CONTRACT
                                    //////////////////////////////////////////////////////////////*/
/**
 * @title DSCEngine
 * @author Abraham Elijah (Mr. Grade)
 * @notice The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1 USD value Peg.
 * This Stablecoin has the properties:
 * - Exogenous Collateral: The collateral is not the native token of the blockchain
 * - Dollar Pegged: The value of the token is pegged to the USD
 * - Algorithmically Stabilized: The system uses an algorithm to stabilize the value of the token
 *
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC.
 * Our DSC system should always be overcollateralized; at no point should the value of the DSC exceed the value of the collateral.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic of minting and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.
 */
contract DSCEngine is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                ///                          ERRORS                          ///
                                //////////////////////////////////////////////////////////////*/
    /// @notice Error thrown when the amount must be greater than zero.
    error DSCEngine__NeedsToBeMoreThanZero();
    
    /// @notice Error thrown when the token addresses and price feed addresses do not match.
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustMatch();
    
    /// @notice Error thrown when the token is not supported.
    error DSCEngine__TokenNotSupported();
    
    /// @notice Error thrown when a transfer fails.
    error DSCEngine__TransferFailed();
    
    /// @notice Error thrown when the health factor is broken.
    error DSCEngine__BrokenHealthFactor(uint256 healthFactor);
    
    /// @notice Error thrown when minting fails.
    error DSCEngine__MintFailed();
    
    /// @notice Error thrown when the health factor is okay.
    error DSCEngine__HealthFactorOk();
    
    /// @notice Error thrown when the health factor has not improved.
    error DSCEngine__HealthFactorNotImproved();

    /*//////////////////////////////////////////////////////////////
                                                        TYPE DECLARATION
                                //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                                        STATE VARIABLES
                                //////////////////////////////////////////////////////////////*/
    uint256 private constant ADDITIONAL_PRECISION = 1e10; // Additional precision for calculations
    uint256 private constant PRECISION = 1e18; // Standard precision for calculations
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // Threshold for liquidation in percentage
    uint256 private constant LIQUIDATION_PRECISION = 100; // Precision for liquidation calculations
    uint256 private constant MIN_HEALTH_FACTOR = 1e18; // Minimum health factor required
    uint256 private constant LIQUIDATION_BONUS = 10; // Bonus for liquidators in percentage

    mapping(address => address) private s_priceFeeds; // Mapping of token addresses to price feed addresses
    mapping(address => mapping(address => uint256)) private s_collateralDeposited; // Mapping of user to token to amount deposited
    mapping(address => uint256) private s_dscMinted; // Mapping of user to amount of DSC minted

    address[] private s_collateralTokens; // Array of collateral tokens

    DecentralizedStableCoin private immutable i_dsc; // Instance of the DecentralizedStableCoin contract

    /*//////////////////////////////////////////////////////////////
                                                            EVENTS
                                //////////////////////////////////////////////////////////////*/
    /// @notice Event emitted when collateral is deposited.
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    
    /// @notice Event emitted when collateral is redeemed.
    event CollateralRedeemed(
        address indexed redeemedFrom, 
        address indexed redeemedTo, 
        address indexed token, 
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                                                        MODIFIERS
                                //////////////////////////////////////////////////////////////*/
    /// @notice Modifier to ensure the amount is greater than zero.
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__NeedsToBeMoreThanZero();
        }
        _;
    }

    /// @notice Modifier to check if the token is allowed.
    modifier isAllowedToken(address _token) {
        if (s_priceFeeds[_token] == address(0)) {
            revert DSCEngine__TokenNotSupported();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /* ------------------------------------------------- CONSTRUCTOR ------------------------------------------------- */
    /**
     * @notice Initializes the DSCEngine contract with token addresses and price feed addresses.
     * @param tokenAddresses Array of token addresses to be used as collateral.
     * @param priceFeedAddresses Array of price feed addresses corresponding to the tokens.
     * @param dscAddress Address of the DecentralizedStableCoin contract.
     * @dev The lengths of tokenAddresses and priceFeedAddresses must match.
     */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustMatch();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /* ------------------------------------------------- EXTERNAL FUNCTIONS ------------------------------------------------- */

    /**
     * @notice Allows users to deposit collateral and mint the StableCoin (DSC).
     * @param tokenCollateralAddress The address of the token to deposit as collateral.
     * @param amountCollateral The amount of collateral to deposit.
     * @param amountDscToMint The amount of decentralized stablecoin to mint.
     */
    function depositCollateralAndMintDSC(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @notice Deposit collateral to mint DSC.
     * @param tokenCollateralAddress Address of the token to deposit as collateral.
     * @param amountCollateral Amount of the token to deposit as collateral.
     * @dev This function follows the Checks-Effects-Interactions (CEI) pattern.
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        // Transfer the collateral from the user to this contract
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        // Interact with the DSC contract to mint DSC
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     * @notice Redeem collateral for DSC.
     * @param tokenCollateralAddress Address of the collateral token.
     * @param amountCollateral Amount of the collateral to be redeemed.
     * @param amountDscToBurn Amount of DSC to burn.
     */
    function redeemCollateralForDSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)
        external
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        // Redeemed collateral already checks health factor.
    }

    /**
     * @notice Redeem collateral.
     * @param tokenCollateralAddress Address of the collateral token.
     * @param amountCollateral Amount of the collateral to be redeemed.
     * @dev This function follows the Checks-Effects-Interactions (CEI) pattern.
     */
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     * @notice Burn the Decentralized Stablecoin minted.
     * @param amount Amount of DSC to burn.
     */
    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); // This should not hit under normal circumstances.
    }

    /**
     * @notice Mint DSC by depositing collateral.
     * @param amountDscToMint Amount of DSC to mint.
     * @dev Users must have more collateral value than the minimum threshold.
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) {
        s_dscMinted[msg.sender] += amountDscToMint;
        // If they minted more than the minimum threshold, they can't mint DSC.
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    /**
     * @notice Liquidate a user's collateral if their health factor is broken.
     * @param collateral Address of the collateral token to liquidate from the user.
     * @param user Address of the user to liquidate (User who has broken the health factor).
     * @param debtToCover Amount of DSC to cover.
     * @notice You can partially liquidate a user's debt.
     * @notice You'll receive a liquidation bonus if you liquidate a user's debt.
     * @dev This function assumes the protocol will be roughly 200% overcollateralized.
     */
    function liquidate(address collateral, address user, uint256 debtToCover)
        external
        moreThanZero(debtToCover)
        nonReentrant
    {
        // Check: health factor of the user
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }
        // We want to burn their DSC "debt" and take their collateral.
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        // Give the liquidator a bonus of 10%.
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(collateral, totalCollateralToRedeem, user, msg.sender);
        // Burn the DSC
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= userHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     * @notice Get the health factor of the user.
     * @dev This function is currently not implemented.
     */
    function getHealthFactor() external view {}

    /* ------------------------------------------------- PRIVATE & INTERNAL VIEW FUNCTIONS ------------------------------------------------- */

    /**
     * @notice Get account information for a user.
     * @param user User address to check account information for.
     * @return totalDscMinted Total DSC minted by the user.
     * @return totalCollateralValueInUsd Total collateral value in USD.
     */
    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 totalCollateralValueInUsd)
    {
        totalDscMinted = s_dscMinted[user];
        totalCollateralValueInUsd = getAccountCollateralValueInUsd(user);
    }

    /**
     * @notice Calculate the health factor of a user.
     * @param user User address to check health factor for.
     * @return healthFactor The calculated health factor.
     */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 totalCollateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold =
            (totalCollateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return collateralAdjustedForThreshold * PRECISION / totalDscMinted;
    }

    /**
     * @notice Revert if the health factor of the user is broken.
     * @param user User's address to check health factor if broken.
     */
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BrokenHealthFactor(userHealthFactor);
        }
    }

    /**
     * @notice Redeem collateral from the user.
     * @param tokenCollateralAddress Address of the collateral token.
     * @param amountCollateral Amount of the collateral to redeem.
     * @param from Address of the user redeeming the collateral.
     * @param to Address to send the redeemed collateral to.
     */
    function _redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to)
        internal
    {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     * @notice Low-level internal function to burn DSC.
     * @param amountDscToBurn Amount of DSC to burn.
     * @param onBehalf Address of the user who is burning the DSC.
     * @param dscFrom Address of the user who is burning the DSC.
     */
    function _burnDsc(uint256 amountDscToBurn, address onBehalf, address dscFrom) internal {
        s_dscMinted[onBehalf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    /* ------------------------------------------------- Public & External View Functions ------------------------------------------------- */

    /**
     * @notice Get the total value of all collateral deposited by the user in USD.
     * @param user User address to check collateral value for.
     * @return totalCollateralValueInUsd Total collateral value in USD.
     */
    function getAccountCollateralValueInUsd(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    /**
     * @notice Get the USD value of a specific token amount.
     * @param token Address of the token to get the value for.
     * @param amount Amount of the token to convert to USD.
     * @return usdValue The calculated USD value.
     */
    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (uint256(price) * ADDITIONAL_PRECISION * amount) / PRECISION;
    }

    /**
     * @notice Get the token amount equivalent to a specified USD amount.
     * @param token Address of the token to convert from USD.
     * @param usdAmountInWei Amount in USD to convert to token amount.
     * @return tokenAmount The calculated token amount.
     */
    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_PRECISION);
    }

    /**
     * @notice Get account information for a user.
     * @param user User address to check account information for.
     * @return totalDscMinted Total DSC minted by the user.
     * @return totalCollateralValueInUsd Total collateral value in USD.
     */
    function getAccountInformation(address user)
        external
        view
        returns (uint256 totalDscMinted, uint256 totalCollateralValueInUsd)
    {
        (totalDscMinted, totalCollateralValueInUsd) = _getAccountInformation(user);
    }
}
