const { ethers, upgrades } = require("hardhat");

const ERC20_TOKEN = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";

async function main() {
  const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  const crowdfunding = await upgrades.deployProxy(CrowdFunding, [ERC20_TOKEN], {
    kind: "uups",
  });
  await crowdfunding.deployed();
  console.log("CrowdFunding deployed to:", crowdfunding.address);
}

main();
