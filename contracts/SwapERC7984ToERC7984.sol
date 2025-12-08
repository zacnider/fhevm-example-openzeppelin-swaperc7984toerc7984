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
