import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers, getChainId } = hre;
  const { deploy } = deployments;
  const { deployer } = await ethers.getNamedSigners();
  console.log("deployer: ", deployer.address);
  const chainId = await getChainId();
  console.log("chainId: ", chainId);

  const network = await deployer.provider.getNetwork();
  console.log("network: ", network.chainId);

  const xerc20Res = await deploy("XERC20", {
    contract: "src/XERC20.sol:XERC20",
    from: deployer.address,
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        init: {
          methodName: "initialize",
          args: [
            [8453n, 84531n].includes(network.chainId)
              ? "BasedZoomerCoin"
              : "ZoomerCoin",
            "ZOOMER",
            deployer.address,
          ],
        },
      },
    },
    log: true,
  });
  console.log("xerc20Res.address: ", xerc20Res.address);
  console.log("xerc20Res.transactionHash: ", xerc20Res.transactionHash);
  const xerc20 = await ethers.getContractAt(
    "src/XERC20.sol:XERC20",
    xerc20Res.address
  );
  console.log("xerc20.name: ", await xerc20.name());
  console.log("xerc20.symbol: ", await xerc20.symbol());
  console.log("xerc20.decimals: ", await xerc20.decimals());
  console.log("xerc20.totalSupply: ", await xerc20.totalSupply());

  if (["1", "5"].includes(chainId)) {
    const xerc20LockboxRes = await deploy("XERC20Lockbox", {
      contract: "src/XERC20Lockbox.sol:XERC20Lockbox",
      from: deployer.address,
      proxy: {
        proxyContract: "OpenZeppelinTransparentProxy",
        execute: {
          init: {
            methodName: "initialize",
            args: [
              xerc20Res.address,
              chainId === "1"
                ? "0x0D505C03d30e65f6e9b4Ef88855a47a89e4b7676"
                : "0x7ea6eA49B0b0Ae9c5db7907d139D9Cd3439862a1",
              false,
            ],
          },
        },
      },
      log: true,
    });
    console.log("xerc20LockboxRes: ", xerc20LockboxRes.address);
    console.log(
      "xerc20LockboxRes.transactionHash: ",
      xerc20LockboxRes.transactionHash
    );

    const lockbox = await xerc20.lockbox();
    console.log("lockbox: ", lockbox);
    if (lockbox !== xerc20LockboxRes.address) {
      await xerc20.setLockbox(xerc20LockboxRes.address);
    }
  }
};
export default func;
func.tags = ["XERC20"];
