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