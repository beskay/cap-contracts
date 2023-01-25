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
    // 'NZD-USD': {
    //   name: 'New Zealand Dollar / U.S. Dollar',
    //   category: 'fx',
    //   maxLeverage: 100,
    //   maxDeviation: 500,
    //   fee: 3,
    //   chainlinkFeed: ADDRESS_ZERO,
    //   liqThreshold: 9900,
    //   fundingFactor: 2000,
    //   minOrderAge: 1,
    //   pythMaxAge: 10,
    //   pythFeed: '0x92eea8ba1b00078cdc2ef6f64f091f262e8c7d0576ee4677572f314ebfafa4c7',
    //   allowChainlinkExecution: false,
    //   isReduceOnly: false
    // },
    // 'USD-MXN': {
    //   name: 'U.S. Dollar / Mexican Peso',
    //   category: 'fx',
    //   maxLeverage: 100,
    //   maxDeviation: 500,
    //   fee: 5,
    //   chainlinkFeed: ADDRESS_ZERO,
    //   liqThreshold: 9900,
    //   fundingFactor: 2000,
    //   minOrderAge: 1,
    //   pythMaxAge: 10,
    //   pythFeed: '0xe13b1c1ffb32f34e1be9545583f01ef385fde7f42ee66049d30570dc866b77ca',
    //   allowChainlinkExecution: false,
    //   isReduceOnly: false
    // },
    // 'USD-SGD': {
    //   name: 'U.S. Dollar / Singapore Dollar',
    //   category: 'fx',
    //   maxLeverage: 100,
    //   maxDeviation: 500,
    //   fee: 5,
    //   chainlinkFeed: ADDRESS_ZERO,
    //   liqThreshold: 9900,
    //   fundingFactor: 2000,
    //   minOrderAge: 1,
    //   pythMaxAge: 10,
    //   pythFeed: '0x396a969a9c1480fa15ed50bc59149e2c0075a72fe8f458ed941ddec48bdb4918',
    //   allowChainlinkExecution: false,
    //   isReduceOnly: false
    // },
    // 'USD-ZAR': {
    //   name: 'U.S. Dollar / South African Rand',
    //   category: 'fx',
    //   maxLeverage: 100,
    //   maxDeviation: 500,
    //   fee: 5,
    //   chainlinkFeed: ADDRESS_ZERO,
    //   liqThreshold: 9900,
    //   fundingFactor: 2000,
    //   minOrderAge: 1,
    //   pythMaxAge: 10,
    //   pythFeed: '0x389d889017db82bf42141f23b61b8de938a4e2d156e36312175bebf797f493f1',
    //   allowChainlinkExecution: false,
    //   isReduceOnly: false
    // },
    'USD-JPY': {
      name: 'U.S. Dollar / Japanese Yen',
      category: 'fx',
      maxLeverage: 100,
      maxDeviation: 500,
      fee: 3,
      chainlinkFeed: ADDRESS_ZERO,
      liqThreshold: 9900,
      fundingFactor: 2000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0xef2c98c804ba503c6a707e38be4dfbb16683775f195b091252bf24693042fd52',
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