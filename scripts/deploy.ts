import { ethers } from "hardhat";

async function main() {
  const ZeroTrade = await ethers.getContractFactory("ZeroTrade");
  const zeroTrade = await ZeroTrade.deploy();
  await zeroTrade.deployed();
  console.log(`ZeroTrade deployed to ${zeroTrade.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
