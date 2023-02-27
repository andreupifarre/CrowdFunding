require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");

const { alchemyApiKey } = require("./secrets.json");

module.exports = {
  solidity: "0.8.16",
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
      },
    },
  },
  paths: {
    artifacts: "./src/artifacts",
    sources: "./src/contracts",
    cache: "./src/cache",
    tests: "./src/test",
  },
};
