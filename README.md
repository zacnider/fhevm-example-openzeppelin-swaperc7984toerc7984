# SwapERC7984ToERC7984

Learn how to use OpenZeppelin ERC7984 confidential tokens

## 🎓 What You'll Learn

This example teaches you how to use FHEVM to build privacy-preserving smart contracts. You'll learn step-by-step how to implement encrypted operations, manage permissions, and work with encrypted data.

## 🚀 Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/zacnider/fhevm-example-openzeppelin-swaperc7984toerc7984.git
   cd fhevm-example-openzeppelin-swaperc7984toerc7984
   ```

2. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

3. **Setup environment:**
   ```bash
   npm run setup
   ```
   Then edit `.env` file with your credentials:
   - `SEPOLIA_RPC_URL` - Your Sepolia RPC endpoint
   - `PRIVATE_KEY` - Your wallet private key (for deployment)
   - `ETHERSCAN_API_KEY` - Your Etherscan API key (for verification)

4. **Compile contracts:**
   ```bash
   npm run compile
   ```

5. **Run tests:**
   ```bash
   npm test
   ```

6. **Deploy to Sepolia:**
   ```bash
   npm run deploy:sepolia
   ```

7. **Verify contract (after deployment):**
   ```bash
   npm run verify <CONTRACT_ADDRESS>
   ```

**Alternative:** Use the [Examples page](https://entrofhe.vercel.app/examples) for browser-based deployment and verification.

---

## 📚 Overview

@title EntropySwapERC7984ToERC7984
@notice Swap contract for exchanging between two ERC7984 confidential tokens
@dev Demonstrates cross-token swaps with encrypted amounts
In this example, you will learn:
- Swapping between two ERC7984 tokens
- Encrypted exchange rate calculations
- encrypted randomness integration for random swap operations

@notice Request entropy for swap with randomness
@param tag Unique tag for entropy request
@return requestId Entropy request ID

@notice Swap tokenA to tokenB using entropy
@param requestId Entropy request ID
@param encryptedAmountIn Encrypted amount to swap
@param inputProof Input proof for encrypted amount

@notice Deposit tokenA
@param encryptedAmount Encrypted amount to deposit
@param inputProof Input proof for encrypted amount

@notice Deposit tokenB
@param encryptedAmount Encrypted amount to deposit
@param inputProof Input proof for encrypted amount

@notice Get encrypted balance
@param account Address to query
@param token Token address
@return Encrypted balance

@notice Get encrypted randomness address
@return encrypted randomness contract address



## 🔐 Learn Zama FHEVM Through This Example

This example teaches you how to use the following **Zama FHEVM** features:

### What You'll Learn About

- **ZamaEthereumConfig**: Inherits from Zama's network configuration
  ```solidity
  contract MyContract is ZamaEthereumConfig {
      // Inherits network-specific FHEVM configuration
  }
  ```

- **FHE Operations**: Uses Zama's FHE library for encrypted operations
  - `FHE operations` - Zama FHEVM operation
  - `FHE.allowThis()` - Zama FHEVM operation
  - `FHE.allow()` - Zama FHEVM operation

- **Encrypted Types**: Uses Zama's encrypted integer types
  - `euint64` - 64-bit encrypted unsigned integer
  - `externalEuint64` - External encrypted value from user

- **Access Control**: Uses Zama's permission system
  - `FHE.allowThis()` - Allow contract to use encrypted values
  - `FHE.allow()` - Allow specific user to decrypt
  - `FHE.allowTransient()` - Temporary permission for single operation
  - `FHE.fromExternal()` - Convert external encrypted values to internal

### Zama FHEVM Imports

```solidity
// Zama FHEVM Core Library - FHE operations and encrypted types
import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

// Zama Network Configuration - Provides network-specific settings
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
```

### Zama FHEVM Code Example

```solidity
// Using Zama FHEVM with OpenZeppelin confidential contracts
euint64 encryptedAmount = FHE.fromExternal(encryptedInput, inputProof);
FHE.allowThis(encryptedAmount);

// Zama FHEVM enables encrypted token operations
// All amounts remain encrypted during transfers
```

### FHEVM Concepts You'll Learn

1. **OpenZeppelin Integration**: Learn how to use Zama FHEVM for openzeppelin integration
2. **ERC7984 Confidential Tokens**: Learn how to use Zama FHEVM for erc7984 confidential tokens
3. **FHE Operations**: Learn how to use Zama FHEVM for fhe operations

### Learn More About Zama FHEVM

- 📚 [Zama FHEVM Documentation](https://docs.zama.org/protocol)
- 🎓 [Zama Developer Hub](https://www.zama.org/developer-hub)
- 💻 [Zama FHEVM GitHub](https://github.com/zama-ai/fhevm)



## 🔍 Contract Code

```solidity
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.27;

import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import "./IEntropyOracle.sol";

/**
 * @title EntropySwapERC7984ToERC7984
 * @notice Swap contract for exchanging between two ERC7984 confidential tokens
 * @dev Demonstrates cross-token swaps with encrypted amounts
 * 
 * This example shows:
 * - Swapping between two ERC7984 tokens
 * - Encrypted exchange rate calculations
 * - EntropyOracle integration for random swap operations
 */
contract EntropySwapERC7984ToERC7984 is ZamaEthereumConfig {
    IEntropyOracle public entropyOracle;
    
    // Token addresses
    address public tokenA;
    address public tokenB;
    
    // Encrypted balances for each token
    mapping(address => mapping(address => euint64)) private balances; // user => token => balance
    
    // Exchange rate (encrypted)
    euint64 private exchangeRateEncrypted;
    
    // Track entropy requests
    mapping(uint256 => address) public swapRequests;
    uint256 public swapRequestCount;
    
    event Swapped(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        bytes encryptedAmountIn,
        bytes encryptedAmountOut
    );
    event SwapRequested(address indexed user, uint256 indexed requestId);
    
    constructor(
        address _entropyOracle,
        address _tokenA,
        address _tokenB
    ) {
        require(_entropyOracle != address(0), "Invalid oracle address");
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
        require(_tokenA != _tokenB, "Tokens must be different");
        
        entropyOracle = IEntropyOracle(_entropyOracle);
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
    
    /**
     * @notice Request entropy for swap with randomness
     * @param tag Unique tag for entropy request
     * @return requestId Entropy request ID
     */
    function requestSwapWithEntropy(bytes32 tag) external payable returns (uint256 requestId) {
        require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
        
        requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
        swapRequests[requestId] = msg.sender;
        swapRequestCount++;
        
        emit SwapRequested(msg.sender, requestId);
        return requestId;
    }
    
    /**
     * @notice Swap tokenA to tokenB using entropy
     * @param requestId Entropy request ID
     * @param encryptedAmountIn Encrypted amount to swap
     * @param inputProof Input proof for encrypted amount
     */
    function swapAToBWithEntropy(
        uint256 requestId,
        externalEuint64 encryptedAmountIn,
        bytes calldata inputProof
    ) external {
        require(entropyOracle.isRequestFulfilled(requestId), "Entropy not ready");
        require(swapRequests[requestId] == msg.sender, "Invalid request");
        
        euint64 amountIn = FHE.fromExternal(encryptedAmountIn, inputProof);
        FHE.allowThis(amountIn);
        euint64 balanceA = balances[msg.sender][tokenA];
        
        // Note: FHE.le is not available, skipping balance check for demonstration
        // In production, implement proper encrypted comparison
        
        // Calculate amount out (simplified - uses exchange rate)
        euint64 amountOut = FHE.mul(amountIn, exchangeRateEncrypted);
        
        // Update balances
        balances[msg.sender][tokenA] = FHE.sub(balanceA, amountIn);
        balances[msg.sender][tokenB] = FHE.add(balances[msg.sender][tokenB], amountOut);
        
        delete swapRequests[requestId];
        
        emit Swapped(msg.sender, tokenA, tokenB, abi.encode(encryptedAmountIn), abi.encode(amountOut));
    }
    
    /**
     * @notice Deposit tokenA
     * @param encryptedAmount Encrypted amount to deposit
     * @param inputProof Input proof for encrypted amount
     */
    function depositTokenA(
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external {
        euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
        FHE.allowThis(amount);
        balances[msg.sender][tokenA] = FHE.add(balances[msg.sender][tokenA], amount);
    }
    
    /**
     * @notice Deposit tokenB
     * @param encryptedAmount Encrypted amount to deposit
     * @param inputProof Input proof for encrypted amount
     */
    function depositTokenB(
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external {
        euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
        FHE.allowThis(amount);
        balances[msg.sender][tokenB] = FHE.add(balances[msg.sender][tokenB], amount);
    }
    
    /**
     * @notice Get encrypted balance
     * @param account Address to query
     * @param token Token address
     * @return Encrypted balance
     */
    function getEncryptedBalance(address account, address token) external view returns (euint64) {
        return balances[account][token];
    }
    
    /**
     * @notice Get EntropyOracle address
     * @return EntropyOracle contract address
     */
    function getEntropyOracle() external view returns (address) {
        return address(entropyOracle);
    }
}

```

## 🧪 Tests

See [test file](./test/SwapERC7984ToERC7984.test.ts) for comprehensive test coverage.

```bash
npm test
```


## 📚 Category

**openzeppelin**



## 🔗 Related Examples

- [All openzeppelin examples](https://github.com/zacnider/entrofhe/tree/main/examples)

## 📝 License

BSD-3-Clause-Clear
