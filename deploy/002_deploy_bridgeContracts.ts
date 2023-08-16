import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { MaxUint256, ZeroAddress } from "ethers";
import { XERC20Lockbox } from "../typechain-types";

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
      contract: "src/OpL1XERC20Bridge.sol:OpL1XERC20Bridge",
      from: deployer.address,
      proxy: {
        proxyContract: "OpenZeppelinTransparentProxy",
        execute: {
          init: {
            methodName: "initialize",
            args: [
              deployer.address,
              xerc20.address,
              l1CrossDomainMessengerAddresses[network.chainId.toString()],
            ],
          },
        },
      },
      log: true,
    });
    console.log("opBridge L1 deployed to:", opBridgeRes.address);
    const opBridge = await ethers.getContractAt(
      "src/OpL1XERC20Bridge.sol:OpL1XERC20Bridge",
      opBridgeRes.address
    );
    console.log("opBridge L1 zoomer: ", await opBridge.zoomer());
    bridgeAddress = opBridgeRes.address;

    const lockbox: XERC20Lockbox = await ethers.getContract("XERC20Lockbox");
    const bridge = await lockbox.OpL1XERC20BRIDGE();
    if (bridge !== bridgeAddress) {
      const res = await lockbox.setOpL1XERC20Bridge(bridgeAddress);
      console.log("setOpL1XERC20BRIDGE tx: ", res.hash);
      await res.wait();
      console.log("setOpL1XERC20BRIDGE done");
    }

    const _xerc20 = await opBridge.zoomer();
    if (_xerc20 !== xerc20.address) {
      const res = await opBridge.setZoomer(xerc20.address);
      console.log("setZoomer tx: ", res.hash);
      await res.wait();
      console.log("setZoomer done");
    }
  }

  if ([8453n, 84531n].includes(network.chainId)) {
    console.log("Deploying L2 side...");
    const opBridgeRes = await deploy("OpL2XERC20Bridge", {
      from: deployer.address,
      proxy: {
        proxyContract: "OpenZeppelinTransparentProxy",

        execute: {
          init: {
            methodName: "initialize",
            args: [deployer.address, xerc20.address],
          },
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

    const _xerc20 = await opBridge.zoomer();
    if (_xerc20 !== xerc20.address) {
      const res = await opBridge.setZoomer(xerc20.address);
      console.log("setZoomer tx: ", res.hash);
      await res.wait();
      console.log("setZoomer done");
    }
  }

  if (bridgeAddress) {
    console.log("Setting limits...");
    const _xerc20 = await ethers.getContractAt(
      "src/XERC20.sol:XERC20",
      xerc20.address
    );
    const maxSupply = 69000000000000000000000000000n;
    const mintLimit = await _xerc20.mintingMaxLimitOf(bridgeAddress);
    console.log("mintLimit: ", mintLimit);
    const burnLimit = await _xerc20.burningMaxLimitOf(bridgeAddress);
    console.log("burnLimit: ", burnLimit);
    if (mintLimit != maxSupply || burnLimit != maxSupply) {
      const res = await _xerc20.setLimits(
        bridgeAddress,
        maxSupply,
        maxSupply
      );
      console.log("setLimits tx: ", res.hash);
      await res.wait();
      console.log("setLimits done");
    }
  }
};
export default func;
func.tags = ["BridgeContracts"];
