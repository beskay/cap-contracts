exports.ADDRESS_ZERO = '0x0000000000000000000000000000000000000000';
exports.BPS_DIVIDER = 10000;
exports.CHAINLINK_FEED = '0x6ce185860a4963106506C203335A2910413708e9';

exports.toUnits = function (amount, units) {
  return ethers.utils.parseUnits('' + amount, units || 18);
};

exports.PRODUCTS = {
  'ETH-USD': {
    name: 'Ethereum / U.S. Dollar',
    category: 'crypto',
    maxLeverage: 50,
    maxDeviation: 10000, // TEST on local only
    chainlinkFeed: this.CHAINLINK_FEED,
    fee: 10, // 0.1%
    liqThreshold: 9900,
    fundingFactor: 10000,
    allowChainlinkExecution: true,
    isClosed: false,
    isReduceOnly: false,
  },
  'BTC-USD': {
    name: 'Bitcoin / U.S. Dollar',
    category: 'crypto',
    maxLeverage: 50,
    maxDeviation: 10000, // TEST on local only
    fee: 10,
    chainlinkFeed: this.CHAINLINK_FEED,
    liqThreshold: 9900,
    fundingFactor: 10000,
    allowChainlinkExecution: true,
    isClosed: false,
    isReduceOnly: false,
  },
  'EUR-USD': {
    name: 'Euro / U.S. Dollar',
    category: 'fx',
    maxLeverage: 100,
    maxDeviation: 10000, // TEST on local only
    fee: 3,
    chainlinkFeed: this.CHAINLINK_FEED,
    liqThreshold: 9900,
    fundingFactor: 10000,
    allowChainlinkExecution: true,
    isClosed: false,
    isReduceOnly: false,
  },
  'XAU-USD': {
    name: 'Gold / U.S. Dollar',
    category: 'commodities',
    maxLeverage: 20,
    maxDeviation: 10000, // TEST on local only
    fee: 10,
    chainlinkFeed: this.CHAINLINK_FEED,
    liqThreshold: 9500,
    fundingFactor: 10000,
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
