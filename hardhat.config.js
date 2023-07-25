require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
const fs = require('fs');
// const infuraId = fs.readFileSync(".infuraid").toString().trim() || "";
require('dotenv').config();
//require("@nomicfoundation/hardhat-toolbox");

// task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
//   const accounts = await hre.ethers.getSigners();

//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

module.exports = {
  defaultNetwork: "localhost",
  networks: {
    hardhat: {
      chainId: 1337
    },
    localhost: {
      chainId: 1337
    },
    ganache: {
      url: process.env.URL_LOCALHOST_GANACHE,
      accounts: [ process.env.GANACHE_PRIVATE_KEY ],
      chainId: 1337
    },
    goerli: {
      url: process.env.ALCHEMY_API_URL_GOERLI,
      accounts: [ process.env.PRIVATE_KEY ]
    },
    mumbai: {
      url: process.env.ALCHEMY_API_URL_MUMBAI,
      accounts: [process.env.PRIVATE_KEY]
    },
    sepolia: {
      url: process.env.ALCHEMY_API_URL_SEPOLIA,
      accounts: [process.env.PRIVATE_KEY]
    },    
    baseGoerli: {
      url: 'https://goerli.base.org',
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000,
    }
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};