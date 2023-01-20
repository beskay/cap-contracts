exports.ADDRESS_ZERO = '0x0000000000000000000000000000000000000000';
exports.BPS_DIVIDER = 10000;

// Chainlink feeds (Arbitrum), base asset USD
exports.ETH_FEED = '0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612';
exports.BTC_FEED = '0x6ce185860a4963106506C203335A2910413708e9';
exports.EUR_FEED = '0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84';
exports.XAU_FEED = '0x1F954Dc24a49708C26E0C1777f16750B5C6d5a2c';

exports.toUnits = function (amount, units) {
  return ethers.utils.parseUnits('' + amount, units || 18);
};

exports.PRODUCTS = {
  'ETH-USD': {
    name: 'Ethereum / U.S. Dollar',
    category: 'crypto',
    maxLeverage: 50,
    maxDeviation: 1000,
    chainlinkFeed: this.ETH_FEED,
    fee: 10, // 0.1%
    liqThreshold: 9900,
    fundingFactor: 10000,
    minOrderAge: 0,
    pythMaxAge: 0,
    pythFeedId: '0x0000000000000000000000000000000000000000000000000000000000000000',
    allowChainlinkExecution: true,
    isClosed: false,
    isReduceOnly: false,
  },
  'BTC-USD': {
    name: 'Bitcoin / U.S. Dollar',
    category: 'crypto',
    maxLeverage: 50,
    maxDeviation: 1000,
    fee: 10,
    chainlinkFeed: this.BTC_FEED,
    liqThreshold: 9900,
    fundingFactor: 10000,
    minOrderAge: 0,
    pythMaxAge: 0,
    pythFeedId: '0x0000000000000000000000000000000000000000000000000000000000000000',
    allowChainlinkExecution: true,
    isClosed: false,
    isReduceOnly: false,
  },
  'EUR-USD': {
    name: 'Euro / U.S. Dollar',
    category: 'fx',
    maxLeverage: 100,
    maxDeviation: 1000,
    fee: 3,
    chainlinkFeed: this.EUR_FEED,
    liqThreshold: 9900,
    fundingFactor: 10000,
    minOrderAge: 0,
    pythMaxAge: 0,
    pythFeedId: '0x0000000000000000000000000000000000000000000000000000000000000000',
    allowChainlinkExecution: true,
    isClosed: false,
    isReduceOnly: false,
  },
  'XAU-USD': {
    name: 'Gold / U.S. Dollar',
    category: 'commodities',
    maxLeverage: 20,
    maxDeviation: 1000,
    fee: 10,
    chainlinkFeed: this.XAU_FEED,
    liqThreshold: 9500,
    fundingFactor: 10000,
    minOrderAge: 0,
    pythMaxAge: 0,
    pythFeedId: '0x0000000000000000000000000000000000000000000000000000000000000000',
    allowChainlinkExecution: true,
    isClosed: false,
    isReduceOnly: false,
  },
};

// ethers.utils.parseUnits(num, decimals); eth => wei
// ethers.utils.formatUnits(num, decimals); wei => eth

exports.formatEvent = function (args) {
  if (!args || !args.length) return;
  let formattedEvent = [];
  for (const item of args) {
    let formattedItem;
    if (ethers.BigNumber.isBigNumber(item)) {
      formattedItem = item.toString();
    } else {
      formattedItem = item;
    }
    // if (typeof(formattedItem) == 'string' && !formattedItem.includes("x") && formattedItem * 1 > 10**12) {
    //   formattedItem = ethers.utils.formatUnits(formattedItem);
    // }
    formattedEvent.push(formattedItem);
  }
  return formattedEvent;
};

exports.logReceipt = (receipt) => {
  console.log('\tReceipt success:', receipt && receipt.status == 1);
  console.log('\tGas used:', receipt.gasUsed.toNumber());

  const events = receipt.events;

  for (const ev of events) {
    if (ev.event) {
      console.log('\t' + ev.event);
      console.log(this.formatEvent(ev.args));
    }
  }
};
