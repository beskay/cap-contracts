const hre = require("hardhat");
const { ethers } = require('hardhat');

async function main() {

  const network = hre.network.name;
  console.log('Network', network);

  const provider = ethers.provider;

  const [signer] = await ethers.getSigners();

  // Account
  const account = await signer.getAddress();
  console.log('Account', account);

  const dataStoreAddress = "0x31B693DDa8e36edACBaef79A8094c33EfF72a151";

  // Chainlink
  const Chainlink = await ethers.getContractFactory('ChainlinkBase');
  const chainlink = await Chainlink.deploy();
  await chainlink.deployed();
  console.log(`Chainlink deployed to ${chainlink.address}.`);

  const dataStore = await (await ethers.getContractFactory("DataStore")).attach(dataStoreAddress);

  await dataStore.setAddress('Chainlink', chainlink.address, true);
  console.log('DataStore configured.');

  const orders = await (await ethers.getContractFactory("Orders")).attach(await dataStore.getAddress("Orders"));
  const positions = await (await ethers.getContractFactory("Positions")).attach(await dataStore.getAddress("Positions"));
  const processor = await (await ethers.getContractFactory("Processor")).attach(await dataStore.getAddress("Processor"));

  // Link
  await orders.link();
  await positions.link();
  await processor.link();
  console.log(`Contracts linked.`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});