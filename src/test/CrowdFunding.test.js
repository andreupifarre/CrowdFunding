const { expect } = require("chai");

const USDC_TOKEN = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
const USDC_WHALE = "0xaaef851977578d9cdf0042fb88f4532b9ef602b2";

const toUsdc = (value) =>
  ethers.utils.parseUnits(value.toString(), 6).toString();

let CrowdFunding;
let crowdfunding;
let deployer;
let pledgee;
let pledger;
let usdc;
let whale;
let deadline;

before(async function () {
  // Deploy CrowdFunding
  CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  crowdfunding = await upgrades.deployProxy(CrowdFunding, [USDC_TOKEN]);
  [deployer, pledgee, pledger] = await ethers.getSigners();

  // Add USDC tokens to account by impersonating account
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [USDC_WHALE],
  });

  whale = await ethers.getSigner(USDC_WHALE);
  usdc = await ethers.getContractAt("IERC20Upgradeable", USDC_TOKEN);

  const amount = 1000n * 10n ** 6n;
  console.log("USDC balance of whale", await usdc.balanceOf(USDC_WHALE));
  await usdc.connect(whale).transfer(pledger.address, amount);
  console.log("USDC balance of account", await usdc.balanceOf(pledger.address));

  // Set deadline
  const now = (await ethers.provider.getBlock("latest")).timestamp;
  deadline = now + 10;
});

describe("CrowdFunding", function () {
  it("should create a campaign", async function () {
    await (
      await crowdfunding.connect(pledgee).createCampaign(toUsdc(2), deadline)
    ).wait();

    expect((await crowdfunding.campaigns(0)).target.toString()).to.equal(
      toUsdc(2)
    );
  });

  it("should be able to pledge", async function () {
    await (
      await usdc.connect(pledger).approve(crowdfunding.address, toUsdc(1))
    ).wait();

    await (await crowdfunding.connect(pledger).pledge(0, toUsdc(1))).wait();

    expect((await crowdfunding.campaigns(0)).raised.toString()).to.equal(
      toUsdc(1)
    );
  });

  it("should be able to refund", async function () {
    await ethers.provider.send("evm_mine", [deadline]);

    await (await crowdfunding.connect(pledger).refund(0)).wait();

    expect(
      (await crowdfunding.connect(pledger).getPledged(0)).toString()
    ).to.equal("0");
  });

  it("should be able to withdraw", async function () {
    const newDeadline = deadline + 10;

    await (
      await crowdfunding.connect(pledgee).createCampaign(toUsdc(1), newDeadline)
    ).wait();

    await (
      await usdc.connect(pledger).approve(crowdfunding.address, toUsdc(1))
    ).wait();

    await (await crowdfunding.connect(pledger).pledge(1, toUsdc(1))).wait();

    await ethers.provider.send("evm_mine", [newDeadline]);

    await (await crowdfunding.connect(pledgee).withdraw(1)).wait();

    expect((await crowdfunding.campaigns(1)).raised.toString()).to.equal("0");
  });
});
