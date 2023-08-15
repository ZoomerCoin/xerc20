import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { MaxUint256, ZeroAddress } from "ethers";

const l1CrossDomainMessengerAddresses: Record<string, string> = {
  "1": "0x866E82a600A1414e583f7F13623F1aC5d58b0Afa",
  "5": "0x8e5693140eA606bcEB98761d9beB1BC87383706D",
};

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers } = hre;
  const { deploy } = deployments;
  const { deployer } = await ethers.getNamedSigners();
  console.log("deployer: ", deployer.address);

  const network = await deployer.provider.getNetwork();
  console.log("network: ", network.chainId);

  console.log("Deploying OP Bridge Contracts...");
  const xerc20 = await deployments.get("XERC20");
  if (!xerc20) {
    throw new Error("XERC20 not deployed");
  }

  let bridgeAddress: string | undefined;
  if ([1n, 5n].includes(network.chainId)) {
    console.log("Deploying L1 side...");
    const opBridgeRes = await deploy("OpL1XERC20Bridge", {
      from: deployer.address,
      proxy: {
        proxyContract: "OpenZeppelinTransparentProxy",
        execute: {
          methodName: "initialize",
          args: [
            deployer.address,
            xerc20.address,
            l1CrossDomainMessengerAddresses[network.chainId.toString()],
          ],
        },
      },
      log: true,
    });
    console.log("opBridge L1 deployed to:", opBridgeRes.address);
    const opBridge = await ethers.getContractAt(
      "OpL1XERC20Bridge",
      opBridgeRes.address
    );
    console.log("opBridge L1 zoomer: ", await opBridge.zoomer());
    bridgeAddress = opBridgeRes.address;
  }

  if ([8453n, 84531n].includes(network.chainId)) {
    console.log("Deploying L2 side...");
    const opBridgeRes = await deploy("OpL2XERC20Bridge", {
      from: deployer.address,
      proxy: {
        proxyContract: "OpenZeppelinTransparentProxy",
        execute: {
          methodName: "initialize",
          args: [deployer.address, xerc20.address],
        },
      },
      log: true,
    });
    console.log("opBridge L2 deployed to:", opBridgeRes.address);
    const opBridge = await ethers.getContractAt(
      "OpL2XERC20Bridge",
      opBridgeRes.address
    );
    console.log("opBridge L2 zoomer: ", await opBridge.zoomer());
    bridgeAddress = opBridgeRes.address;
  }

  if (bridgeAddress) {
    console.log("Setting limits...");
    const _xerc20 = await ethers.getContractAt("src/XERC20.sol:XERC20", xerc20.address);
    const res = await _xerc20.setLimits(bridgeAddress, MaxUint256, MaxUint256);
    console.log("setLimits tx: ", res.hash);
    await res.wait();
    console.log("setLimits done");
  }
};
export default func;
func.tags = ["BridgeContracts"];
