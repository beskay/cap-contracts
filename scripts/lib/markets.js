// Chainlink feeds
exports.chainlinkFeeds = {
  ETH: '0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612',
  USDC: '0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3',
  BTC: '0x6ce185860a4963106506C203335A2910413708e9'
};

exports.MARKETS = {
  'ETH-USD': {
    name: 'Ethereum / U.S. Dollar',
    category: 'crypto',
    maxLeverage: 50,
    maxDeviation: 10000, // TEST on local only
    chainlinkFeed: this.chainlinkFeeds['ETH'],
    fee: 10, // 0.1%
    liqThreshold: 9900,
    fundingFactor: 10000,
    minOrderAge: 1,
    pythMaxAge: 10,
    pythFeed: '0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace',
    allowChainlinkExecution: true,
    isReduceOnly: false
  },
  'BTC-USD': {
    name: 'Bitcoin / U.S. Dollar',
    category: 'crypto',
    maxLeverage: 50,
    maxDeviation: 10000, // TEST on local only
    fee: 10,
    chainlinkFeed: this.chainlinkFeeds['BTC'],
    liqThreshold: 9900,
    fundingFactor: 10000,
    minOrderAge: 1,
    pythMaxAge: 10,
    pythFeed: '0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43',
    allowChainlinkExecution: true,
    isReduceOnly: false
  },
  'EUR-USD': {
    name: 'Euro / U.S. Dollar',
    category: 'fx',
    maxLeverage: 100,
    maxDeviation: 10000, // TEST on local only
    fee: 3,
    chainlinkFeed: '0xa14d53bc1f1c0f31b4aa3bd109344e5009051a84',
    liqThreshold: 9900,
    fundingFactor: 10000,
    minOrderAge: 1,
    pythMaxAge: 10,
    pythFeed: '0xa995d00bb36a63cef7fd2c287dc105fc8f3d93779f062f09551b0af3e81ec30b',
    allowChainlinkExecution: true,
    isReduceOnly: false
  },
  'XAU-USD': {
    name: 'Gold / U.S. Dollar',
    category: 'commodities',
    maxLeverage: 20,
    maxDeviation: 10000, // TEST on local only
    fee: 10,
    chainlinkFeed: '0x1f954dc24a49708c26e0c1777f16750b5c6d5a2c',
    liqThreshold: 9500,
    fundingFactor: 10000,
    minOrderAge: 1,
    pythMaxAge: 10,
    pythFeed: '0x765d2ba906dbc32ca17cc11f5310a89e9ee1f6420508c63861f2f8ba4ee34bb2',
    allowChainlinkExecution: true,
    isReduceOnly: false
  }
};