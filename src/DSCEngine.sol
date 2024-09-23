// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

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
 * @notice  The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1 USD value Peg.
 * This Stablecoin has the properties:
 * - Exogenous Collateral: The collateral is not the native token of the blockchain
 * - Dollar Pegged: The value of the token is pegged to the USD
 * - Algorithmically Stabilized: The system uses an algorithm to stabilize the value of the token
 *
 * it is simimlar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC
 * Our DSC system should always be overcollateralized, at no point should the value of the DSC exceed the value of the collateral
 *
 * @notice This contract is the core of the DSC System. It handles all the logic of minting and redeeming DSC, as well as depositing & withdrawing collateral
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.
 */
contract DSCEngine is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                ///                          ERRORS                          ///
                                //////////////////////////////////////////////////////////////*/
    //
    error DSCEngine__NeedsToBeMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustMatch();
    error DSCEngine__TokenNotSupported();
    error DSCEngine__TransferFailed();
    error DSCEngine__BrokenHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    /*//////////////////////////////////////////////////////////////
                                                        TYPE DECLARATION
                                //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                                        STATE VARRIABLES
                                //////////////////////////////////////////////////////////////*/
    uint256 private constant ADDITIONAL_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10;

    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; // userToTokenToAmount
    mapping(address user => uint256) private s_dscMinted; // userToAmount

    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    /*//////////////////////////////////////////////////////////////
                                                            EVENTS
                                //////////////////////////////////////////////////////////////*/
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                                                        MODIFIERS
                                //////////////////////////////////////////////////////////////*/
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__NeedsToBeMoreThanZero();
        }
        _;
    }

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

    /// @notice This Function allow users to deposit collateral and mint the StableCoin (DSC)
    /// @param tokenCollateralAddress: The address of the token to dpeosit as collateral
    /// @param amountCollateral: The amount of collateral to deposit
    /// @param amountDscToMint: the amount of decentralizedstablecoin to mint
    function depositCollateralAndMintDSC(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @dev Deposit collateral to mint DSC
     * @param tokenCollateralAddress Address of the token to deposit as collateral
     * @param amountCollateral : Amount of the token to deposit as collateral
     * @notice This functions follows CEI (Checks-Effects-Interactions) pattern
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

    function redeemCollateralForDSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)
        external
    {
        burnDsc(amountDscToBurn);
        reedemCollateral(tokenCollateralAddress, amountCollateral);
        // redeemed collateral already checks health factor.
    }

    /**
     *
     * @param tokenCollateralAddress Address of the collateral token
     * @param amountCollateral amount of the collateral to be redeemed.
     */

    /**
     * in order to redeem collateral:
     * 1. Health factor must be over 1 AFTER  collateral is pulled
     *     DRY: Don't Repeat Yourself:
     *     CEI: Checks Effects and Interactions.
     */
    function reedemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    // Burn the Decentralized Stable coin minted.
    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); // I don'th think this would ever hit..
    }

    /**
     *
     * @notice This functions follows CEI (Checks-Effects-Interactions) pattern
     * @param amountDscToMint Amount of DSC to mint
     * @dev Mint DSC by depositing collateral
     * @notice they  must have more collateral value than the minimum threshold
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) {
        s_dscMinted[msg.sender] += amountDscToMint;
        // if they minted more than the minimum threshold, they can't mint DSC
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    /**
     * @param collateral: Address of the collateral token to liquidate from the user.
     * @param user: Address of the user to liquidate (User who has broken the _healthFactor.
     * @param debtToCover: Amount of DSC to cover.
     * @notice you can partially liquidate a user's debt
     * @notice you'll get a liquidation bonous if you liquidate a user's debt
     * @notice this function working assumes the protocol will be roughly 200% overcollateralized in order for this to work.
     * @notice A known bug would be if the protocol were 100% or less collateralized, then we wouldn't be able to incentivize liquidators.
     *      - For example, if the price of the collateral plummeted before anyone could be liquidated, then the protocol would be insolvent.
     *     - Follow CEI (Checks-Effects-Interactions) pattern
     */
    function liquidate(address collateral, address user, uint256 debtToCover)
        external
        moreThanZero(debtToCover)
        nonReentrant
    {
        // check: health factor of the user
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }
        // we  want to burn their DSC "debt"
        // take their collateral
        // Bad User:
        // - $140 ETH, $100 DSC
        // - debtToCover = $100
        // $100 DSC -> ?? ETH
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        // give the liquidator a bonous of 10%
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(collateral, totalCollateralToRedeem, user, msg.sender);
        // burn the DSC
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= userHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function gethealthFactor() external view {}

    /* ------------------------------------------------- PRIVATE & INTERNAL VIEW FUNCTIONS ------------------------------------------------- */

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 totalCollateralValueInUsd)
    {
        totalDscMinted = s_dscMinted[user];
        totalCollateralValueInUsd = getAccountCollateralValueInUsd(user);
    }
    /**
     * @dev Calculate the health factor  of a user, and returns how close to liquidation they are
     * @param user: User address to check health factor for.
     *
     */

    function _healthFactor(address user) private view returns (uint256) {
        // total Dsc Minited
        // total collateral value
        (uint256 totalDscMinted, uint256 totalCollateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold =
            (totalCollateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return collateralAdjustedForThreshold * PRECISION / totalDscMinted;
    }

    /**
     *
     * @param user : User's address to check health factor if broken.
     */
    function _revertIfHealthFactorIsBroken(address user) internal view {
        // if the health factor is below the threshold, revert

        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BrokenHealthFactor(userHealthFactor);
        }

        // Check: health factor (do they have more collateral value than the minimum threshold)
        // Revert: if the health factor is below the threshold
    }

    function _redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to)
        internal
    {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     * @dev Low-level internal function, do now call unless the function calling it has already checked the health factor
     * @param amountDscToBurn: Amount of DSC to burn
     * @param onBehalf : Address of the user who is burning the DSC
     * @param dscFrom : Address of the user who is burning the DSC
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
    function getAccountCollateralValueInUsd(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // Get the total value of all the collateral deposited by the user
        // For each token deposited as collateral, get the value of the token in USD
        // Multiply the amount of the token by the value of the token in US
        // Add all the values together
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (uint256(price) * ADDITIONAL_PRECISION * amount) / PRECISION;
    }

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_PRECISION);
    }

    function getAccountInformation(address user)
        external
        view
        returns (uint256 totalDscMinted, uint256 totalCollateralValueInUsd)
    {
        (totalDscMinted, totalCollateralValueInUsd) = _getAccountInformation(user);
    }
}
