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

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Decentralized Stable Coin
 * @author Abraham Elijah
 * @notice This contract implements a decentralized stablecoin system.
 * @dev This contract is governed by the DSCEngine and serves as the ERC20 implementation of the stablecoin.
 * Collateral: Exogenous (ETC & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    /*//////////////////////////////////////////////////////////////
                             ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Error thrown when the amount must be greater than zero.
    error DecentralizedStableCoin__MustBeMoreThanZero();
    
    /// @notice Error thrown when the burn amount exceeds the balance.
    error ERC20Burnable__BurnAmountExceedsBalance();
    
    /// @notice Error thrown when the address is zero.
    error DecentralizedStableCoin__NotZeroAddress();

    /// @notice Initializes the stablecoin with a name and symbol.
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    /**
     * @notice Burns tokens from the caller's account.
     * @dev This function allows the owner to burn a specified amount of tokens.
     * @param _amount The amount of tokens to burn.
     * @custom:error Must be more than zero.
     * @custom:error Burn amount exceeds balance.
     */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert ERC20Burnable__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    /**
     * @notice Mints new tokens to a specified address.
     * @dev This function allows the owner to mint new tokens.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     * @return bool Returns true if minting was successful.
     * @custom:error Address cannot be zero.
     * @custom:error Amount must be greater than zero.
     */
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }

        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
