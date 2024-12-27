import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
require('@openzeppelin/hardhat-upgrades');

require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.23',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },    
  },

  networks: {
    // for mainnet
    'base-mainnet': {
      url: 'https://mainnet.base.org',
      accounts: [process.env.DEV_GENIECAT_PRIVATE_KEY as string],
      gasPrice: 1000000000,
    },
    // for testnet
    'base-sepolia': {
      url: 'https://sepolia.base.org',
      accounts: [process.env.DEV_GENIECAT_PRIVATE_KEY as string],
      gasPrice: 1000000000,
    },
    // for local dev environment
    'base-local': {
      url: 'http://localhost:8545',
      accounts: [process.env.DEV_GENIECAT_PRIVATE_KEY as string],
      gasPrice: 1000000000,
    },
  },
  defaultNetwork: 'hardhat',
};

export default config;