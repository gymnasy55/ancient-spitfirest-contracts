import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { utils } from "ethers";
import { ethers } from "hardhat";
import { FR, FR__factory } from "../typechain";

describe("Greeter", function () {
  let contract: FR;
  let signer: SignerWithAddress;

  before(async () => {
    [signer] = await ethers.getSigners();

    contract = await (await new FR__factory(signer).deploy()).deployed();
  })
  it("Should return the new greeting once it's changed", async function () {
    const reserveTokenA = utils.parseEther('1000');
    const reserveTokenB = utils.parseEther('2000');

    const amountIn = utils.parseEther('100');
    const slippage = 11;
    const amountOutMin = amountIn.mul(100).div(slippage + 100);

    console.log(amountOutMin);

    const amountEth = await contract.calculateAmountToSend(reserveTokenA, reserveTokenB, amountIn, amountOutMin);

    console.log(utils.formatEther(amountEth));
  });
});
