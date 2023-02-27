const { ethers, upgrades } = require("hardhat");

const CROWDFUNDING_ADDRESS = "0x840748F7Fd3EA956E5f4c88001da5CC1ABCBc038";

async function main() {
  const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  const crowdfunding = await upgrades.upgradeProxy(
    CROWDFUNDING_ADDRESS,
    CrowdFunding,
    {
      kind: "uups",
    }
  );
  console.log("CrowdFunding upgraded");
}

main();
