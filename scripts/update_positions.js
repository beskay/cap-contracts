const hre = require("hardhat");
const { ethers } = require('hardhat');
const { MARKETS, chainlinkFeeds } = require('./lib/markets.js');

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

  // Positions
  const Positions = await ethers.getContractFactory("Positions");
  const positions = await Positions.deploy(roleStoreAddress, dataStoreAddress);
  await positions.deployed();
  console.log(`Positions deployed to ${positions.address}.`);

  const roleStore = await (await ethers.getContractFactory("RoleStore")).attach(roleStoreAddress);

  const CONTRACT_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("CONTRACT"));
  await roleStore.grantRole(positions.address, CONTRACT_ROLE);
  console.log('Roles granted.');

  const dataStore = await (await ethers.getContractFactory("DataStore")).attach(dataStoreAddress);
  await dataStore.setAddress("Positions", positions.address, true);
  console.log('DataStore configured.');

  const processor = await (await ethers.getContractFactory("Processor")).attach(await dataStore.getAddress("Processor"));

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