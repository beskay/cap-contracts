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

  const roleStoreAddress = "0x685B7A09a0c5aC9D03505eFa078fdD7Ab38c2FaA";
  const dataStoreAddress = "0xe9d3C9bB9A2047E7467f4770dfA0d62E2a411792";

  // Orders
  const Orders = await ethers.getContractFactory("Orders");
  const orders = await Orders.deploy(roleStoreAddress, dataStoreAddress);
  await orders.deployed();
  console.log(`Orders deployed to ${orders.address}.`);

  const roleStore = await (await ethers.getContractFactory("RoleStore")).attach(roleStoreAddress);

  const CONTRACT_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("CONTRACT"));
  await roleStore.grantRole(orders.address, CONTRACT_ROLE);
  console.log('Roles granted.');

  const dataStore = await (await ethers.getContractFactory("DataStore")).attach(dataStoreAddress);
  await dataStore.setAddress("Orders", orders.address, true);
  console.log('DataStore configured.');

  const processor = await (await ethers.getContractFactory("Processor")).attach(await dataStore.getAddress("Processor"));

  await orders.link();
  await processor.link();
  console.log('Contracts linked.');

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});