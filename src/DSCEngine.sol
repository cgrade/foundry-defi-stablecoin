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




    /*//////////////////////////////////////////////////////////////
                                 IMPORT
  //////////////////////////////////////////////////////////////*/
pragma solidity ^0.8.19;


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
contract DSCEngine {
    /*//////////////////////////////////////////////////////////////
       ///                          ERRORS                          ///
    //////////////////////////////////////////////////////////////*///
    error DSCEngine__NeedsToBeMoreThanZero();

    /*//////////////////////////////////////////////////////////////
                            TYPE DECLARATION
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            STATE VARRIABLES
    //////////////////////////////////////////////////////////////*/
    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

     /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__NeedsToBeMoreThanZero();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddress, address dscAddress) {}


    /* ------------------------------------------------- EXTERNAL FUNCTIONS ------------------------------------------------- */
    function depositCollateralAndMintDSC() external {}

    /**
     * @dev Deposit collateral to mint DSC
     * @param tokenCollateralAddress Address of the token to deposit as collateral
     * @param amountCollateral : Amount of the token to deposit as collateral
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external more {
        // 
    }
    function redeemCollateralForDSC() external {}
    function reedemCollateral() external {}
    function burnDsc() external {}
    function mintDsc() external {}
    function liquidate() external {}

    function healthFactor() view external {}
}