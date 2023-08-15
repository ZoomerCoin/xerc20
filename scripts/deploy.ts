import { ZeroAddress } from "ethers";
import { ethers, upgrades } from "hardhat";

// https://docs.base.org/base-contracts
const l1CrossDomainMessengerAddresses: Record<string, string> = {
  "1": "0x866E82a600A1414e583f7F13623F1aC5d58b0Afa",
  "5": "0x8e5693140eA606bcEB98761d9beB1BC87383706D",
  "31337": ZeroAddress,
};

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("deployer: ", deployer.address);
  const chainId = (await deployer.provider.getNetwork()).chainId;
  console.log("chainId: ", chainId);

  const XERC20 = await ethers.getContractFactory("src/XERC20.sol:XERC20");
  const xerc20 = await upgrades.deployProxy(XERC20, [
    "BasedZoomer",
    "ZOOMER",
    deployer.address,
  ]);
  await xerc20.waitForDeployment();
  console.log("xerc20 deployed to:", await xerc20.getAddress());
  console.log("name: ", await xerc20.name());
  console.log("symbol: ", await xerc20.symbol());
  console.log("owner: ", await xerc20.owner());
  console.log("totalSupply: ", await xerc20.totalSupply());
  console.log("balanceOf: ", await xerc20.balanceOf(deployer.address));

  console.log("Deploying OP Bridge Contracts...");
  if ([1n, 5n].includes(chainId)) {
    console.log("Deploying L1 side...");
    const OPBridge = await ethers.getContractFactory("OpL1XERC20Bridge");
    const opBridge = await upgrades.deployProxy(OPBridge, [
      deployer.address,
      await xerc20.getAddress(),
      l1CrossDomainMessengerAddresses[chainId.toString()],
    ]);
    await opBridge.waitForDeployment();
    console.log("opBridge L1 deployed to:", await opBridge.getAddress());
    console.log("opBridge L1 zoomer: ", await opBridge.zoomer());
  }

  if ([8453n, 84531n, 31337n].includes(chainId)) {
    console.log("Deploying L2 side...");
    const OPBridge = await ethers.getContractFactory("OpL2XERC20Bridge");
    const opBridge = await upgrades.deployProxy(OPBridge, [
      deployer.address,
      await xerc20.getAddress(),
    ]);
    await opBridge.waitForDeployment();
    console.log("opBridge L2 deployed to:", await opBridge.getAddress());
    console.log("opBridge L2 zoomer: ", await opBridge.zoomer());
  }
}

main();
