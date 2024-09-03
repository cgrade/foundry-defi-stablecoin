# Decentralized Stablecoin Project

This project implements a decentralized stablecoin system using Solidity and OpenZeppelin libraries. The system includes a stablecoin contract (`DecentralizedStableCoin`) and an engine contract (`DSCEngine`) to manage the minting, burning, and collateralization of the stablecoin.

## Contracts

### DecentralizedStableCoin

The `DecentralizedStableCoin` contract is an ERC20 token with burnable functionality. It inherits from OpenZeppelin's `ERC20Burnable` and `Ownable` contracts.

#### Features

- **Minting**: The contract allows minting of new tokens.
- **Burning**: Only the owner can burn tokens.
- **Ownership**: The contract uses OpenZeppelin's `Ownable` to manage ownership.

#### Errors

- `DecentralizedStableCoin__MustBeMoreThanZero`: Thrown when the burn amount is zero or less.
- `ERC20Burnable__BurnAmountExceedsBalance`: Thrown when the burn amount exceeds the balance.

### DSCEngine

The `DSCEngine` contract manages the collateralization and health factor of users.

#### Functions

- `_getAccountInformation(address user)`: Returns the total DSC minted and the total collateral value in USD for a user.
- `_healthFactor(address user)`: Calculates and returns the health factor of a user.
- `revertIfHealthFactorIsBroken()`: Reverts the transaction if the user's health factor is below the threshold.

## Installation

1. Clone the repository:

   ```sh
   git clone https://github.com/cgrade/foundry-defi-stablecoin.git
   cd decentralized-stablecoin
   ```

2. Install dependencies:

   ```sh
   forge install
   ```

3. Compile the contracts:
   ```sh
   forge build
   ```

## Usage

1. Deploy the contracts:

   ```sh
   forge script script/Deploy.s.sol --broadcast
   ```

2. Interact with the contracts using Foundry console:
   ```sh
   forge console
   ```

## Testing

Run the tests to ensure the contracts work as expected:

```sh
forge test
```
