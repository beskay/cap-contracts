const hre = require('hardhat');
const { ethers } = require('hardhat');
const { MARKETS, chainlinkFeeds } = require('./lib/markets.js');
const { ADDRESS_ZERO } = require('./lib/utils.js');

async function main() {
  const network = hre.network.name;
  console.log('Network', network);

  const provider = ethers.provider;

  const [signer, _oracle] = await ethers.getSigners();

  // Account
  const account = await signer.getAddress();
  console.log('Account', account);

  // TODO: update marketstore contract to accept empty chainlink
  const marketStore = await (
    await ethers.getContractFactory('MarketStore')
  ).attach('0x4C933a69eB6D2988b52873Daf8aC952326Dfa415');

  const marketsToAdd = MARKETS;

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
