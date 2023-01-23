const hre = require("hardhat");
const { ethers } = require('hardhat');
const { chainlinkFeeds } = require('./lib/markets.js');
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

  const marketsToAdd = {
    'SPY': {
      name: 'SPDR S&P 500 ETF TRUST',
      category: 'indices',
      maxLeverage: 20,
      maxDeviation: 500,
      chainlinkFeed: ADDRESS_ZERO,
      fee: 10, // 0.1%
      liqThreshold: 9900,
      fundingFactor: 3000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0x19e09bb805456ada3979a7d1cbb4b6d63babc3a0f8e8a9509f68afa5c4c11cd5',
      allowChainlinkExecution: false,
      isReduceOnly: false
    },
    'QQQ': {
      name: 'Invesco NASDAQ-100 ETF',
      category: 'indices',
      maxLeverage: 20,
      maxDeviation: 500,
      chainlinkFeed: ADDRESS_ZERO,
      fee: 10, // 0.1%
      liqThreshold: 9900,
      fundingFactor: 3000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0x9695e2b96ea7b3859da9ed25b7a46a920a776e2fdae19a7bcfdf2b219230452d',
      allowChainlinkExecution: false,
      isReduceOnly: false
    },
  };

  for (const id in marketsToAdd) {
    const _market = marketsToAdd[id];
    await marketStore.set(id, _market);
    console.log('Added ', id);
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});