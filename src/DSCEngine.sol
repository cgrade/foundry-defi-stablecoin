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
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    /*//////////////////////////////////////////////////////////////
                                                        TYPE DECLARATION
                                //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                                        STATE VARRIABLES
                                //////////////////////////////////////////////////////////////*/
    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; // userToTokenToAmount

    DecentralizedStableCoin private immutable i_dsc;

    /*//////////////////////////////////////////////////////////////
                                                            EVENTS
                                //////////////////////////////////////////////////////////////*/
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

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
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /* ------------------------------------------------- EXTERNAL FUNCTIONS ------------------------------------------------- */
    function depositCollateralAndMintDSC() external {}

    /**
     * @dev Deposit collateral to mint DSC
     * @param tokenCollateralAddress Address of the token to deposit as collateral
     * @param amountCollateral : Amount of the token to deposit as collateral
     * @notice This functions follows CEI (Checks-Effects-Interactions) pattern
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
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

    function redeemCollateralForDSC() external {}
    function reedemCollateral() external {}
    function burnDsc() external {}
    function mintDsc() external {}
    function liquidate() external {}

    function healthFactor() external view {}
}
