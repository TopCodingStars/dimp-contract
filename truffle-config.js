const HDWalletProvider = require("@truffle/hdwallet-provider");

require("dotenv").config();

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    mainnet: {
      provider: () =>
        new HDWalletProvider(process.env.MNEMONIC, `https://polygon-rpc.com/`),
      network_id: 137,
      networkCheckTimeout: 10000000,
      confirmations: 0,
      timeoutBlocks: 5000,
      skipDryRun: true,
    },
    mumbai: {
      provider: () =>
        new HDWalletProvider(
          process.env.MNEMONIC,
          `https://polygon-mumbai.g.alchemy.com/v2/r4Crw3pW-4jfWKjon-ijnD0AjlFJGLQj`,
        ),
      network_id: 80001,
      networkCheckTimeout: 50000,
      confirmations: 2,
      timeoutBlocks: 100000,
      skipDryRun: true,
    },
  },
  mocha: {
    // timeout: 100000
  },
  compilers: {
    solc: {
      version: "0.8.20",
      settings: {
        optimizer: {
          enabled: false,
          runs: 200,
        },
        evmVersion: "byzantium",
      },
    },
  },
  db: {
    enabled: false,
  },
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    polygonscan: process.env.POLYGONSCAN_API,
  },
};
