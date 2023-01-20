const { utils } = require('ethers');
const { ADDRESS_ZERO, BPS_DIVIDER, PRODUCTS, getMarketProperty, toUnits } = require('./utils.js');

exports.setup = async function () {
  const provider = ethers.provider;
  const [signer, _oracle, user1, user2] = await ethers.getSigners();

  // Mock Tokens - CAP, USDC
  const MockToken = await ethers.getContractFactory('MockToken');

  const cap = await MockToken.deploy('CAP', 'CAP', 18);
  await cap.deployed();
  console.log(`CAP token deployed to ${cap.address}.`);

  const usdc = await MockToken.deploy('USDC', 'USDC', 6);
  await usdc.deployed();
  console.log(`USDC token deployed to ${usdc.address}.`);

  // Mock price store
  const MockChainlink = await ethers.getContractFactory('MockChainlink');
  const chainlink = await MockChainlink.deploy();
  await chainlink.deployed();
  console.log(`MockChainlink deployed to ${chainlink.address}.`);

  // Oracle
  const oracle = { address: await _oracle.getAddress() };

  // CONTRACT DEPLOYMENT //

  // Stores and helpers

  // Governable
  const Governable = await ethers.getContractFactory('Governable');
  const governable = await Governable.deploy();
  await governable.deployed();
  console.log(`Governable deployed to ${governable.address}.`);

  // RoleStore
  const RoleStore = await ethers.getContractFactory('RoleStore');
  const roleStore = await RoleStore.deploy();
  await roleStore.deployed();
  console.log(`RoleStore deployed to ${roleStore.address}.`);

  console.log('--------');

  // DataStore
  const DataStore = await ethers.getContractFactory('DataStore');
  const dataStore = await DataStore.deploy();
  await dataStore.deployed();
  console.log(`DataStore deployed to ${dataStore.address}.`);

  console.log('--------');

  // // Chainlink
  // const Chainlink = await ethers.getContractFactory("Chainlink");
  // const chainlink = await Chainlink.deploy();
  // await chainlink.deployed();
  // console.log(`Chainlink deployed to ${chainlink.address}.`);

  // console.log('--------');

  // AssetStore
  const AssetStore = await ethers.getContractFactory('AssetStore');
  const assetStore = await AssetStore.deploy(roleStore.address);
  await assetStore.deployed();
  console.log(`AssetStore deployed to ${assetStore.address}.`);

  // FundingStore
  const FundingStore = await ethers.getContractFactory('FundingStore');
  const fundingStore = await FundingStore.deploy(roleStore.address);
  await fundingStore.deployed();
  console.log(`FundingStore deployed to ${fundingStore.address}.`);

  // FundStore
  const FundStore = await ethers.getContractFactory('FundStore');
  const fundStore = await FundStore.deploy(roleStore.address);
  await fundStore.deployed();
  console.log(`FundStore deployed to ${fundStore.address}.`);

  // MarketStore
  const MarketStore = await ethers.getContractFactory('MarketStore');
  const marketStore = await MarketStore.deploy(roleStore.address);
  await marketStore.deployed();
  console.log(`MarketStore deployed to ${marketStore.address}.`);

  // OrderStore
  const OrderStore = await ethers.getContractFactory('OrderStore');
  const orderStore = await OrderStore.deploy(roleStore.address);
  await orderStore.deployed();
  console.log(`OrderStore deployed to ${orderStore.address}.`);

  // PoolStore
  const PoolStore = await ethers.getContractFactory('PoolStore');
  const poolStore = await PoolStore.deploy(roleStore.address);
  await poolStore.deployed();
  console.log(`PoolStore deployed to ${poolStore.address}.`);

  // PositionStore
  const PositionStore = await ethers.getContractFactory('PositionStore');
  const positionStore = await PositionStore.deploy(roleStore.address);
  await positionStore.deployed();
  console.log(`PositionStore deployed to ${positionStore.address}.`);

  // RiskStore
  const RiskStore = await ethers.getContractFactory('RiskStore');
  const riskStore = await RiskStore.deploy(roleStore.address, dataStore.address);
  await riskStore.deployed();
  console.log(`RiskStore deployed to ${riskStore.address}.`);

  // StakingStore
  const StakingStore = await ethers.getContractFactory('StakingStore');
  const stakingStore = await StakingStore.deploy(roleStore.address);
  await stakingStore.deployed();
  console.log(`StakingStore deployed to ${stakingStore.address}.`);

  // Handlers

  // Funding
  const Funding = await ethers.getContractFactory('Funding');
  const funding = await Funding.deploy(roleStore.address, dataStore.address);
  await funding.deployed();
  console.log(`Funding deployed to ${funding.address}.`);

  // Orders
  const Orders = await ethers.getContractFactory('Orders');
  const orders = await Orders.deploy(roleStore.address, dataStore.address);
  await orders.deployed();
  console.log(`Orders deployed to ${orders.address}.`);

  // Pool
  const Pool = await ethers.getContractFactory('Pool');
  const pool = await Pool.deploy(roleStore.address, dataStore.address);
  await pool.deployed();
  console.log(`Pool deployed to ${pool.address}.`);

  // Positions
  const Positions = await ethers.getContractFactory('Positions');
  const positions = await Positions.deploy(roleStore.address, dataStore.address);
  await positions.deployed();
  console.log(`Positions deployed to ${positions.address}.`);

  // Processor
  const Processor = await ethers.getContractFactory('Processor');
  const processor = await Processor.deploy(roleStore.address, dataStore.address);
  await processor.deployed();
  console.log(`Processor deployed to ${processor.address}.`);

  // Staking
  const Staking = await ethers.getContractFactory('Staking');
  const staking = await Staking.deploy(roleStore.address, dataStore.address);
  await staking.deployed();
  console.log(`Staking deployed to ${staking.address}.`);

  // CONTRACT SETUP //

  // Data

  // Contract addresses
  await dataStore.setAddress('AssetStore', assetStore.address, true);
  await dataStore.setAddress('FundingStore', fundingStore.address, true);
  await dataStore.setAddress('FundStore', fundStore.address, true);
  await dataStore.setAddress('MarketStore', marketStore.address, true);
  await dataStore.setAddress('OrderStore', orderStore.address, true);
  await dataStore.setAddress('PoolStore', poolStore.address, true);
  await dataStore.setAddress('PositionStore', positionStore.address, true);
  await dataStore.setAddress('RiskStore', riskStore.address, true);
  await dataStore.setAddress('StakingStore', stakingStore.address, true);
  await dataStore.setAddress('Funding', funding.address, true);
  await dataStore.setAddress('Orders', orders.address, true);
  await dataStore.setAddress('Pool', pool.address, true);
  await dataStore.setAddress('Positions', positions.address, true);
  await dataStore.setAddress('Processor', processor.address, true);
  await dataStore.setAddress('Staking', staking.address, true);
  await dataStore.setAddress('CAP', cap.address, true);
  await dataStore.setAddress('USDC', usdc.address, true);
  await dataStore.setAddress('Chainlink', chainlink.address, true);
  await dataStore.setAddress('oracle', oracle.address, true);
  console.log(`Data addresses configured.`);

  // Link
  await funding.link();
  await orders.link();
  await pool.link();
  await positions.link();
  await processor.link();
  await staking.link();
  console.log(`Contracts linked.`);

  // Grant roles
  const CONTRACT_ROLE = utils.keccak256(utils.toUtf8Bytes('CONTRACT'));
  const ORACLE_ROLE = utils.keccak256(utils.toUtf8Bytes('ORACLE'));
  await roleStore.grantRole(funding.address, CONTRACT_ROLE);
  await roleStore.grantRole(orders.address, CONTRACT_ROLE);
  await roleStore.grantRole(pool.address, CONTRACT_ROLE);
  await roleStore.grantRole(positions.address, CONTRACT_ROLE);
  await roleStore.grantRole(processor.address, CONTRACT_ROLE);
  await roleStore.grantRole(staking.address, CONTRACT_ROLE);
  await roleStore.grantRole(oracle.address, CONTRACT_ROLE); // oracle also trusted to execute eg closeMarkets
  await roleStore.grantRole(oracle.address, ORACLE_ROLE); // oracle also trusted to execute eg closeMarkets
  console.log(`Roles configured.`);

  // Currencies
  await assetStore.set(ADDRESS_ZERO, { minSize: ethers.utils.parseEther('0.1'), chainlinkFeed: ADDRESS_ZERO });
  await assetStore.set(usdc.address, { minSize: toUnits('100', 6), chainlinkFeed: ADDRESS_ZERO });
  console.log(`Assets configured.`);

  // Markets
  for (const id in PRODUCTS) {
    const _market = PRODUCTS[id];
    await marketStore.set(id, _market);
  }
  console.log(`Markets configured.`);

  // Fund pool store
  //signer.sendTransaction({ to: poolStore.address, value: ethers.utils.parseEther('100') }).then((txObj) => {
  //  console.log('Funded poolStore.', txObj.hash);
  //});

  // Mint and approve some mock tokens

  await usdc.mint(toUnits('100000', 6));
  await usdc.approve(fundStore.address, toUnits('1000000000', 6));
  await cap.mint(toUnits('1000'));
  await cap.approve(fundStore.address, toUnits('1000000000'));

  // To user1
  await usdc.connect(user1).mint(toUnits('100000', 6));
  await usdc.connect(user1).approve(fundStore.address, toUnits('1000000000', 6));
  await cap.connect(user1).mint(toUnits('1000'));
  await cap.connect(user1).approve(fundStore.address, toUnits('1000000000'));

  console.log(`Minted mock tokens.`);

  return {
    provider,
    signer,
    _oracle,
    user1,
    user2,
    usdc,
    chainlink,
    pool,
    orders,
    positions,
    processor,
    orderStore,
    positionStore,
    cap,
  };
};
