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

  const marketsToUpdate = {
  'ETH-USD': {
    name: 'Ethereum / U.S. Dollar',
    category: 'crypto',
    maxLeverage: 50,
    maxDeviation: 500,
    chainlinkFeed: chainlinkFeeds['ETH'],
    fee: 10, // 0.1%
    liqThreshold: 9900,
    fundingFactor: 3000,
    minOrderAge: 1,
    pythMaxAge: 10,
    pythFeed: '0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace',
    allowChainlinkExecution: true,
    isReduceOnly: false
  },
  'BTC-USD': {
    name: 'Bitcoin / U.S. Dollar',
    category: 'crypto',
    maxLeverage: 50,
    maxDeviation: 500,
    fee: 10,
    chainlinkFeed: chainlinkFeeds['BTC'],
    liqThreshold: 9900,
    fundingFactor: 3000,
    minOrderAge: 1,
    pythMaxAge: 10,
    pythFeed: '0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43',
    allowChainlinkExecution: true,
    isReduceOnly: false
  },
  'EUR-USD': {
    name: 'Euro / U.S. Dollar',
    category: 'fx',
    maxLeverage: 100,
    maxDeviation: 500,
    fee: 3,
    chainlinkFeed: '0xa14d53bc1f1c0f31b4aa3bd109344e5009051a84',
    liqThreshold: 9900,
    fundingFactor: 2000,
    minOrderAge: 1,
    pythMaxAge: 10,
    pythFeed: '0xa995d00bb36a63cef7fd2c287dc105fc8f3d93779f062f09551b0af3e81ec30b',
    allowChainlinkExecution: true,
    isReduceOnly: false
  },
  'XAU-USD': {
    name: 'Gold / U.S. Dollar',
    category: 'commodities',
    maxLeverage: 20,
    maxDeviation: 500,
    fee: 10,
    chainlinkFeed: '0x1f954dc24a49708c26e0c1777f16750b5c6d5a2c',
    liqThreshold: 9500,
    fundingFactor: 2000,
    minOrderAge: 1,
    pythMaxAge: 10,
    pythFeed: '0x765d2ba906dbc32ca17cc11f5310a89e9ee1f6420508c63861f2f8ba4ee34bb2',
    allowChainlinkExecution: true,
    isReduceOnly: false
  },
    'AUD-USD': {
      name: 'Australian Dollar / U.S. Dollar',
      category: 'fx',
      maxLeverage: 100,
      maxDeviation: 500,
      fee: 5,
      chainlinkFeed: '0x9854e9a850e7c354c1de177ea953a6b1fba8fc22',
      liqThreshold: 9900,
      fundingFactor: 2000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0x67a6f93030420c1c9e3fe37c1ab6b77966af82f995944a9fefce357a22854a80',
      allowChainlinkExecution: true,
      isReduceOnly: false
    },
    'USD-CNH': {
      name: 'U.S. Dollar / Chinese Yuan',
      category: 'fx',
      maxLeverage: 50,
      maxDeviation: 500,
      fee: 5,
      chainlinkFeed: ADDRESS_ZERO,
      liqThreshold: 9900,
      fundingFactor: 2000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0xeef52e09c878ad41f6a81803e3640fe04dceea727de894edd4ea117e2e332e66',
      allowChainlinkExecution: false,
      isReduceOnly: false
    },
    'USD-CAD': {
      name: 'U.S. Dollar / Canadian Dollar',
      category: 'fx',
      maxLeverage: 100,
      maxDeviation: 500,
      fee: 3,
      chainlinkFeed: ADDRESS_ZERO,
      liqThreshold: 9900,
      fundingFactor: 2000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0x3112b03a41c910ed446852aacf67118cb1bec67b2cd0b9a214c58cc0eaa2ecca',
      allowChainlinkExecution: false,
      isReduceOnly: false
    },
    'GBP-USD': {
      name: 'British Pound / U.S. Dollar',
      category: 'fx',
      maxLeverage: 100,
      maxDeviation: 500,
      fee: 3,
      chainlinkFeed: '0x9c4424fd84c6661f97d8d6b3fc3c1aac2bedd137',
      liqThreshold: 9900,
      fundingFactor: 2000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0x84c2dde9633d93d1bcad84e7dc41c9d56578b7ec52fabedc1f335d673df0a7c1',
      allowChainlinkExecution: true,
      isReduceOnly: false
    },
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
    'USD-CHF': {
      name: 'U.S. Dollar / Swiss Franc',
      category: 'fx',
      maxLeverage: 100,
      maxDeviation: 500,
      fee: 3,
      chainlinkFeed: ADDRESS_ZERO,
      liqThreshold: 9900,
      fundingFactor: 2000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0x0b1e3297e69f162877b577b0d6a47a0d63b2392bc8499e6540da4187a63e28f8',
      allowChainlinkExecution: false,
      isReduceOnly: false
    },
    'XAG-USD': {
      name: 'Silver / U.S. Dollar',
      category: 'commodities',
      maxLeverage: 10,
      maxDeviation: 500,
      fee: 20,
      chainlinkFeed: '0xc56765f04b248394cf1619d20db8082edbfa75b1',
      liqThreshold: 9500,
      fundingFactor: 2000,
      minOrderAge: 1,
      pythMaxAge: 10,
      pythFeed: '0xf2fb02c32b055c805e7238d628e5e9dadef274376114eb1f012337cabe93871e',
      allowChainlinkExecution: true,
      isReduceOnly: false
    },
};

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