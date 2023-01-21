const hre = require('hardhat');
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

  const roleStoreAddress = '0x685B7A09a0c5aC9D03505eFa078fdD7Ab38c2FaA';
  const dataStoreAddress = '0xe9d3C9bB9A2047E7467f4770dfA0d62E2a411792';

  // MarketStore
  const MarketStore = await ethers.getContractFactory('MarketStore');
  const marketStore = await MarketStore.deploy(roleStoreAddress);
  await marketStore.deployed();
  console.log(`MarketStore deployed to ${marketStore.address}.`);

  for (const id in MARKETS) {
    const _market = MARKETS[id];
    await marketStore.set(id, _market);
    console.log('Added ', id);
  }

  const dataStore = await (await ethers.getContractFactory('DataStore')).attach(dataStoreAddress);
  await dataStore.setAddress('MarketStore', marketStore.address, true);
  console.log('DataStore configured.');

  const funding = await (await ethers.getContractFactory('Funding')).attach(await dataStore.getAddress('Funding'));
  const orders = await (await ethers.getContractFactory('Orders')).attach(await dataStore.getAddress('Orders'));
  const positions = await (
    await ethers.getContractFactory('Positions')
  ).attach(await dataStore.getAddress('Positions'));
  const processor = await (
    await ethers.getContractFactory('Processor')
  ).attach(await dataStore.getAddress('Processor'));

  await funding.link();
  await orders.link();
  await positions.link();
  await processor.link();
  console.log('Contracts linked.');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
