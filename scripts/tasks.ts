import { task } from "hardhat/config";

task('FR:upgrade')
    .addPositionalParam('address')
    .setAction(async ({ address }, hre) => {
        const [deployer] = await hre.ethers.getSigners();
        const frFactory = await hre.ethers.getContractFactory('FR', deployer);

        const fr = await hre.upgrades.upgradeProxy(address, frFactory);

        console.log("FR upgrade tx hash:", fr.deployTransaction.hash);

        const frDeployed = await fr.deployed();

        console.log("FR upgrade to:", frDeployed.address);
    })

task('FR:deploy')
    .addPositionalParam('address')
    .setAction(async ({ address }, hre) => {
        const [deployer] = await hre.ethers.getSigners();
        const frFactory = await hre.ethers.getContractFactory('FR', deployer);

        const fr = await hre.upgrades.deployProxy(frFactory);

        console.log("FR deployed tx hash:", fr.deployTransaction.hash);

        const frDeployed = await fr.deployed();

        console.log("FR deployed to:", frDeployed.address);
    })