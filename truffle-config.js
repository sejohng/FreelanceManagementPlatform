require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    sepolia: {
      provider: () =>
        new HDWalletProvider(
          process.env.MNEMONIC,
          `wss://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`
        ),
      network_id: 11155111, // Sepolia network ID
      gas: 25000000, // Gas limit
      gasPrice: 10000, 
      confirmations: 2, // Number of confirmations to wait between deployments
      timeoutBlocks: 200, // Timeout blocks
      skipDryRun: true, // Skip dry run before migrations
    },
  },
  compilers: {
    solc: {
      version: "0.8.26", // Solidity version
    },
  },
};