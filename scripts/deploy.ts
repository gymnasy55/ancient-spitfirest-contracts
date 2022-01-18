import { ethers } from "hardhat";
import { FR__factory } from "../typechain"

async function main() {
  const [deployer] = await ethers.getSigners();

  const fr = await new FR__factory(deployer).deploy();

  console.log("FR deployment tx hash:", fr.deployTransaction.hash);

  const frDeployed = await fr.deployed();

  console.log("FR deployed to:", frDeployed.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
