const hre = require("hardhat");
const { ethers } = require('hardhat');

async function main() {

  const network = hre.network.name;
  console.log('Network', network);

  const provider = ethers.provider;

  const dataStoreAddress = "0xe9d3C9bB9A2047E7467f4770dfA0d62E2a411792";
  const dataStore = await (await ethers.getContractFactory("DataStore")).attach(dataStoreAddress);

  // await dataStore.setAddress("AssetStore", assetStore.address, true);
  // await dataStore.setAddress("FundingStore", fundingStore.address, true);
  // await dataStore.setAddress("FundStore", fundStore.address, true);
  // await dataStore.setAddress("MarketStore", marketStore.address, true);
  // await dataStore.setAddress("OrderStore", orderStore.address, true);
  // await dataStore.setAddress("PoolStore", poolStore.address, true);
  // await dataStore.setAddress("PositionStore", positionStore.address, true);
  // await dataStore.setAddress("RiskStore", riskStore.address, true);
  // await dataStore.setAddress("StakingStore", stakingStore.address, true);
  // await dataStore.setAddress("Funding", funding.address, true);
  // await dataStore.setAddress("Orders", orders.address, true);
  // await dataStore.setAddress("Pool", pool.address, true);
  // await dataStore.setAddress("Positions", positions.address, true);
  // await dataStore.setAddress("Processor", processor.address, true);
  // await dataStore.setAddress("Staking", staking.address, true);
  // await dataStore.setAddress("CAP", cap.address, true);
  // await dataStore.setAddress("USDC", usdc.address, true);
  // await dataStore.setAddress("WBTC", wbtc.address, true);
  // await dataStore.setAddress("Chainlink", chainlink.address, true);
  // await dataStore.setAddress("oracle", oracle.address, true);

  console.log(`
    Contracts (Arbitrum One):
    - AssetStore: ${await dataStore.getAddress('AssetStore')}
    - FundingStore: ${await dataStore.getAddress('FundingStore')}
    - FundStore: ${await dataStore.getAddress('FundStore')}
    - MarketStore: ${await dataStore.getAddress('MarketStore')}
    - OrderStore: ${await dataStore.getAddress('OrderStore')}
    - PoolStore: ${await dataStore.getAddress('PoolStore')}
    - PositionStore: ${await dataStore.getAddress('PositionStore')}
    - RiskStore: ${await dataStore.getAddress('RiskStore')}
    - StakingStore: ${await dataStore.getAddress('StakingStore')}
    - Funding: ${await dataStore.getAddress('Funding')}
    - Orders: ${await dataStore.getAddress('Orders')}
    - Pool: ${await dataStore.getAddress('Pool')}
    - Positions: ${await dataStore.getAddress('Positions')}
    - Processor: ${await dataStore.getAddress('Processor')}
    - Staking: ${await dataStore.getAddress('Staking')}
  `);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});