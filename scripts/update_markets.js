const hre = require("hardhat");
const { ethers } = require('hardhat');
const { MARKETS, chainlinkFeeds } = require('./lib/markets.js');
const { ADDRESS_ZERO } = require('./lib/utils.js');

async function main() {

  const network = hre.network.name;
  console.log('Network', network);

  const provider = ethers.provider;

  const [signer] = await ethers.getSigners();

  // Account
  const account = await signer.getAddress();
  console.log('Account', account);

  const dataStoreAddress = "0xe9d3C9bB9A2047E7467f4770dfA0d62E2a411792";
  const dataStore = await (await ethers.getContractFactory("DataStore")).attach(dataStoreAddress);

  const marketStore = await (await ethers.getContractFactory("MarketStore")).attach(await dataStore.getAddress("MarketStore"));

  const marketsToUpdate = MARKETS;

  for (const id in marketsToUpdate) {
    const _market = marketsToUpdate[id];
    await marketStore.set(id, _market);
    console.log('Updated ', id);
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});