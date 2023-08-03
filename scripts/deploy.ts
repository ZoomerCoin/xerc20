import { ethers, upgrades } from "hardhat";

const ownerAddress = "0x00000000000000000000000000000000deadbeef";

async function main() {
  // Deploying
  const XZoomerCoin = await ethers.getContractFactory("XZoomerCoin");
  const xzoomer = await upgrades.deployProxy(XZoomerCoin, [
    ownerAddress,
    "XZoomerCoin",
    "ZOOMER",
  ]);
  await xzoomer.waitForDeployment();
  console.log("XZoomerCoin deployed to:", await xzoomer.getAddress());
}

main();
