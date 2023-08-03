import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { XZoomerCoin } from "../typechain-types";

describe("XZoomerCoin", function () {
  it("deploys and initializes", async () => {
    const [owner] = await ethers.getSigners();
    const XZoomerCoin = await ethers.getContractFactory("XZoomerCoin");

    const instance: XZoomerCoin = (await upgrades.deployProxy(XZoomerCoin, [
      owner.address,
      "XZoomerCoin",
      "ZOOMER",
    ])) as unknown as XZoomerCoin;
    await instance.waitForDeployment();
    expect(await instance.symbol()).to.equal("ZOOMER");
    expect(await instance.name()).to.equal("XZoomerCoin");
  });
});
