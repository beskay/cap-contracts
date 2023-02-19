const hre = require("hardhat");
const { ethers } = require('hardhat');
const { MARKETS, chainlinkFeeds } = require('./lib/markets.js');

async function main() {

  const network = hre.network.name;
  console.log('Network', network);

  const provider = ethers.provider;

  const [signer, _oracle] = await ethers.getSigners();

  // Account
  const account = await signer.getAddress();
  console.log('Account', account);

  const roleStoreAddress = "0xE1040f058De8C8835cEEBF9d6D1d8c449d989366";
  const dataStoreAddress = "0x360B0B2b3391FD65D8279E2231C80D9De767ad7b";

  // Orders
  const Orders = await ethers.getContractFactory("Orders");
  const orders = await Orders.deploy(roleStoreAddress, dataStoreAddress);
  await orders.deployed();
  console.log(`Orders deployed to ${orders.address}.`);

  // Positions
  const Positions = await ethers.getContractFactory("Positions");
  const positions = await Positions.deploy(roleStoreAddress, dataStoreAddress);
  await positions.deployed();
  console.log(`Positions deployed to ${positions.address}.`);

  const roleStore = await (await ethers.getContractFactory("RoleStore")).attach(roleStoreAddress);

  const CONTRACT_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("CONTRACT"));
  await roleStore.grantRole(orders.address, CONTRACT_ROLE);
  await roleStore.grantRole(positions.address, CONTRACT_ROLE);
  console.log('Roles granted.');


  const dataStore = await (await ethers.getContractFactory("DataStore")).attach(dataStoreAddress);
  await dataStore.setAddress("Orders", orders.address, true);
  await dataStore.setAddress("Positions", positions.address, true);
  console.log('DataStore configured.');

  const processor = await (await ethers.getContractFactory("Processor")).attach(await dataStore.getAddress("Processor"));

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