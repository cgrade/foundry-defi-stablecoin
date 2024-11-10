# Decentralized Stable Coin (DSC) Project

## Overview

The Decentralized Stable Coin (DSC) project implements a decentralized stablecoin system that is algorithmically stabilized and pegged to the USD. The system is designed to maintain a 1:1 value with the USD while being overcollateralized with exogenous assets such as WETH and WBTC. This project includes the core smart contracts for the stablecoin, its engine, and deployment scripts.

## Core Components

### 1. Smart Contracts

- **DecentralizedStableCoin.sol**: Implements the ERC20 standard for the stablecoin, allowing minting and burning of tokens.
- **DSCEngine.sol**: Manages the logic for minting and redeeming the stablecoin, as well as handling collateral deposits and withdrawals.
- **HelperConfig.s.sol**: Provides configuration for deploying the DSC and DSCEngine contracts, including network-specific settings and mock price feeds for testing.

### 2. Mock Contracts

- **MockV3Aggregator.t.sol**: A mock implementation of a price aggregator for testing purposes, simulating the behavior of a price feed.

### 3. Deployment Scripts

- **DeployDSC.s.sol**: Script for deploying the Decentralized Stable Coin and its associated DSCEngine, setting up necessary configurations and addresses.

### 4. Unit Tests

- **DSCEngineTest.t.sol**: Contains unit tests for the DSCEngine contract, ensuring the functionality of collateral deposits, price feed retrieval, and error handling.

## Project Structure

```
project-root/
│
├── script/
│   ├── DeployDSC.s.sol
│   └── HelperConfig.s.sol
│
├── src/
│   ├── DecentralizedStableCoin.sol
│   └── DSCEngine.sol
│
├── test/
│   ├── mocks/
│   │   └── MockV3Aggregator.t.sol
│   └── unit/
│       └── DSCEngineTest.t.sol
│
└── README.md
```

## Installation

To get started with the project, follow these steps:

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Install dependencies**:
   Ensure you have [Foundry](https://book.getfoundry.sh/) installed. Then run:

   ```bash
   forge install
   ```

3. **Compile the contracts**:

   ```bash
   forge build
   ```

4. **Run tests**:
   ```bash
   forge test
   ```

## Usage

### Deploying the Contracts

To deploy the DSC and DSCEngine contracts, run the following command:

```bash
forge script script/DeployDSC.s.sol --broadcast
```

### Interacting with the Contracts

Once deployed, you can interact with the contracts using a web3 provider or through a frontend application. The `DSCEngine` contract provides functions for depositing collateral, minting DSC, and redeeming collateral.

## Testing

The project includes unit tests for the `DSCEngine` contract. To run the tests, use the following command:

```bash
forge test
```

## Contributing

Contributions are welcome! If you have suggestions for improvements or find bugs, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgments

- Special thanks to the OpenZeppelin team for their ERC20 implementation and security libraries.
- Thanks to Chainlink for providing reliable price feeds.

```

```
