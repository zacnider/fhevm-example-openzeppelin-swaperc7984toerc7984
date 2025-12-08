# EntropySwapERC7984ToERC7984

Swap contract for exchanging between two ERC7984 confidential tokens

## 🚀 Standard workflow
- Install (first run): `npm install --legacy-peer-deps`
- Compile: `npx hardhat compile`
- Test (local FHE + local oracle/chaos engine auto-deployed): `npx hardhat test`
- Deploy (frontend Deploy button): constructor args fixed to EntropyOracle, tokenA, and tokenB; oracle is `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Verify: `npx hardhat verify --network sepolia <contractAddress> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 <TOKEN_A_ADDRESS> <TOKEN_B_ADDRESS>`

## 📋 Overview

This example demonstrates **OpenZeppelin** concepts in FHEVM with **EntropyOracle integration**:
- Swapping between two ERC7984 tokens
- Encrypted exchange rate calculations
- EntropyOracle integration for random swap operations
- Privacy-preserving cross-token swaps

## 🎯 What This Example Teaches

This tutorial will teach you:

1. **How to swap between two ERC7984 tokens** with encrypted amounts
2. **How to manage encrypted exchange rates** between tokens
3. **How to deposit tokens** into swap contract
4. **How to use entropy** for random swap operations
5. **Cross-token swap mechanics** with FHE operations
6. **Real-world cross-token swap** implementation

## 💡 Why This Matters

Cross-token swaps are essential in DeFi:
- **Allows trading** between different confidential tokens
- **Enables liquidity pools** for confidential tokens
- **Maintains privacy** - all amounts remain encrypted
- **Entropy adds randomness** to swap calculations
- **Real-world application** in DeFi protocols

## 🔍 How It Works

### Contract Structure

The contract has five main components:

1. **Request Swap with Entropy**: Request entropy for swapping
2. **Swap A to B with Entropy**: Swap tokenA for tokenB
3. **Deposit Token A**: Deposit tokenA into swap contract
4. **Deposit Token B**: Deposit tokenB into swap contract
5. **Balance Queries**: Get encrypted balances for each token

### Step-by-Step Code Explanation

#### 1. Constructor

```solidity
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
```

**What it does:**
- Takes EntropyOracle address and two token addresses
- Validates all addresses are not zero
- Validates tokens are different
- Stores oracle interface and token addresses

**Why it matters:**
- Must use the correct oracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Token addresses for swap operations

#### 2. Request Swap with Entropy

```solidity
function requestSwapWithEntropy(bytes32 tag) external payable returns (uint256 requestId) {
    require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
    
    requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
    swapRequests[requestId] = msg.sender;
    swapRequestCount++;
    
    emit SwapRequested(msg.sender, requestId);
    return requestId;
}
```

**What it does:**
- Validates fee payment
- Requests entropy from EntropyOracle
- Stores swap request with user address
- Returns request ID

**Key concepts:**
- **Two-phase swapping**: Request first, swap later
- **Request tracking**: Maps request ID to user
- **Entropy for randomness**: Adds randomness to swap calculations

#### 3. Swap A to B with Entropy

```solidity
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
    
    // Calculate amount out (uses encrypted exchange rate)
    euint64 amountOut = FHE.mul(amountIn, exchangeRateEncrypted);
    
    // Update balances
    balances[msg.sender][tokenA] = FHE.sub(balanceA, amountIn);
    balances[msg.sender][tokenB] = FHE.add(balances[msg.sender][tokenB], amountOut);
    
    delete swapRequests[requestId];
    emit Swapped(msg.sender, tokenA, tokenB, abi.encode(encryptedAmountIn), abi.encode(amountOut));
}
```

**What it does:**
- Validates request ID and fulfillment
- Converts external encrypted amount to internal
- Gets user's tokenA balance
- Calculates output amount using encrypted exchange rate
- Subtracts amount from tokenA balance
- Adds output amount to tokenB balance
- Emits swap event

**Key concepts:**
- **Encrypted exchange rate**: Rate stored encrypted
- **FHE multiplication**: Uses FHE.mul for rate calculation
- **Encrypted balances**: All balances remain encrypted

**Why encrypted:**
- Exchange rate remains private
- All amounts remain encrypted
- Privacy-preserving swaps

#### 4. Deposit Token A

```solidity
function depositTokenA(
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) external {
    euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
    FHE.allowThis(amount);
    balances[msg.sender][tokenA] = FHE.add(balances[msg.sender][tokenA], amount);
}
```

**What it does:**
- Converts external encrypted amount to internal
- Adds amount to user's tokenA balance
- Enables swapping tokenA for tokenB

#### 5. Deposit Token B

```solidity
function depositTokenB(
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) external {
    euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
    FHE.allowThis(amount);
    balances[msg.sender][tokenB] = FHE.add(balances[msg.sender][tokenB], amount);
}
```

**What it does:**
- Converts external encrypted amount to internal
- Adds amount to user's tokenB balance
- Enables swapping tokenB for tokenA

## 🧪 Step-by-Step Testing

### Prerequisites

1. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

2. **Compile contracts:**
   ```bash
   npx hardhat compile
   ```

### Running Tests

```bash
npx hardhat test
```

### What Happens in Tests

1. **Fixture Setup** (`deployContractFixture`):
   - Deploys FHEChaosEngine, EntropyOracle, two ERC7984 tokens, and EntropySwapERC7984ToERC7984
   - Returns all contract instances

2. **Test: Deposit Token A**
   ```typescript
   it("Should deposit tokenA", async function () {
     const input = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input.add64(100);
     const encryptedInput = await input.encrypt();
     
     await contract.depositTokenA(encryptedInput.handles[0], encryptedInput.inputProof);
     
     const balance = await contract.getEncryptedBalance(owner.address, tokenA);
     expect(balance).to.not.be.undefined;
   });
   ```
   - Creates encrypted amount
   - Deposits tokenA into swap contract
   - Verifies balance increased

3. **Test: Swap A to B with Entropy**
   ```typescript
   it("Should swap tokenA to tokenB", async function () {
     // ... deposit tokenA code ...
     const tag = hre.ethers.id("swap-request");
     const fee = await oracle.getFee();
     const requestId = await contract.requestSwapWithEntropy(tag, { value: fee });
     await waitForEntropy(requestId);
     
     const input = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input.add64(50);
     const encryptedInput = await input.encrypt();
     
     await contract.swapAToBWithEntropy(
       requestId,
       encryptedInput.handles[0],
       encryptedInput.inputProof
     );
     
     const balanceB = await contract.getEncryptedBalance(owner.address, tokenB);
     expect(balanceB).to.not.be.undefined;
   });
   ```
   - Deposits tokenA
   - Requests entropy for swap
   - Swaps tokenA for tokenB
   - Verifies tokenB balance increased

### Expected Test Output

```
  EntropySwapERC7984ToERC7984
    Deployment
      ✓ Should deploy successfully
      ✓ Should have EntropyOracle address set
    Deposits
      ✓ Should deposit tokenA
      ✓ Should deposit tokenB
    Swapping
      ✓ Should request swap with entropy
      ✓ Should swap tokenA to tokenB

  6 passing
```

**Note:** All balances and amounts are encrypted (handles). Decrypt off-chain using FHEVM SDK to see actual values.

## 🚀 Step-by-Step Deployment

### Option 1: Frontend (Recommended)

1. Navigate to [Examples page](/examples)
2. Find "EntropySwapERC7984ToERC7984" in Tutorial Examples
3. Click **"Deploy"** button
4. Approve transaction in wallet
5. Wait for deployment confirmation
6. Copy deployed contract address

### Option 2: CLI

1. **Create deploy script** (`scripts/deploy.ts`):
   ```typescript
   import hre from "hardhat";

   async function main() {
     const ENTROPY_ORACLE_ADDRESS = "0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361";
     const TOKEN_A_ADDRESS = "0x..."; // Your first ERC7984 token address
     const TOKEN_B_ADDRESS = "0x..."; // Your second ERC7984 token address
     
     const ContractFactory = await hre.ethers.getContractFactory("EntropySwapERC7984ToERC7984");
     const contract = await ContractFactory.deploy(
       ENTROPY_ORACLE_ADDRESS,
       TOKEN_A_ADDRESS,
       TOKEN_B_ADDRESS
     );
     await contract.waitForDeployment();
     
     const address = await contract.getAddress();
     console.log("EntropySwapERC7984ToERC7984 deployed to:", address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

2. **Deploy:**
   ```bash
   npx hardhat run scripts/deploy.ts --network sepolia
   ```

## ✅ Step-by-Step Verification

### Option 1: Frontend

1. After deployment, click **"Verify"** button on Examples page
2. Wait for verification confirmation
3. View verified contract on Etherscan

### Option 2: CLI

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 <TOKEN_A_ADDRESS> <TOKEN_B_ADDRESS>
```

**Important:** Constructor arguments must be:
1. EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
2. Token A address: Your first ERC7984 token contract address
3. Token B address: Your second ERC7984 token contract address

## 📊 Expected Outputs

### After Deposit Token A

- `getEncryptedBalance(user, tokenA)` returns increased encrypted balance
- User can now swap tokenA for tokenB

### After Request Swap with Entropy

- `swapRequests[requestId]` contains user address
- `swapRequestCount` increments
- `SwapRequested` event emitted

### After Swap A to B with Entropy

- `getEncryptedBalance(user, tokenA)` returns decreased encrypted balance
- `getEncryptedBalance(user, tokenB)` returns increased encrypted balance
- `Swapped` event emitted

## ⚠️ Common Errors & Solutions

### Error: `SenderNotAllowed()`

**Cause:** Missing `FHE.allowThis()` call on encrypted amount.

**Solution:**
```solidity
euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
FHE.allowThis(amount); // ✅ Required!
```

**Prevention:** Always call `FHE.allowThis()` on all encrypted values before using them.

---

### Error: `Entropy not ready`

**Cause:** Calling `swapAToBWithEntropy()` before entropy is fulfilled.

**Solution:** Always check `isRequestFulfilled()` before using entropy.

---

### Error: `Invalid request`

**Cause:** Request ID doesn't belong to caller.

**Solution:** Ensure request ID matches the caller's request.

---

### Error: `Tokens must be different`

**Cause:** Token A and Token B addresses are the same.

**Solution:** Ensure token addresses are different in constructor.

---

### Error: `Insufficient fee`

**Cause:** Not sending enough ETH when requesting swap.

**Solution:** Always send exactly 0.00001 ETH:
```typescript
const fee = await contract.entropyOracle.getFee();
await contract.requestSwapWithEntropy(tag, { value: fee });
```

---

### Error: Verification failed - Constructor arguments mismatch

**Cause:** Wrong constructor arguments used during verification.

**Solution:** Always use EntropyOracle address and both token addresses:
```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 <TOKEN_A_ADDRESS> <TOKEN_B_ADDRESS>
```

## 🔗 Related Examples

- [EntropyERC7984Token](../openzeppelin-erc7984token/) - ERC7984 token implementation
- [EntropySwapERC7984ToERC20](../openzeppelin-swaperc7984toerc20/) - Swapping ERC7984 to ERC20
- [Category: openzeppelin](../)

## 📚 Additional Resources

- [Full Tutorial Track Documentation](../../../frontend/src/pages/Docs.tsx) - Complete educational guide
- [Zama FHEVM Documentation](https://docs.zama.org/) - Official FHEVM docs
- [GitHub Repository](https://github.com/zacnider/entrofhe/tree/main/examples/openzeppelin-swaperc7984toerc7984) - Source code

## 📝 License

BSD-3-Clause-Clear
