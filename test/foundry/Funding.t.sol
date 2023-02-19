// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import './utils/Setup.t.sol';

contract FundingTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function testFundingTrackerLong() public {
        // execute btc long order
        _submitAndExecuteOrder(user, 10 ether, btcLong, priceFeedDataBTC);

        // open long interest should be 10 ether
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 10 ether);
        // fundingStore.getLastUpdated should be block.timestamp
        assertEq(fundingStore.getLastUpdated(address(0), 'BTC-USD'), block.timestamp);

        // fast forward 1 day
        uint256 newTimestamp = block.timestamp + 1 days;
        skip(1 days);

        // get new pricefeed data to prevent stale orders
        priceFeedDataBTC = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(BTC_PRICE * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(BTC_PRICE * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            // we have to use newTimestamp here, because the compiler causes issues
            // see also https://github.com/foundry-rs/foundry/issues/1373
            uint64(newTimestamp) // publishTime
        );

        // user2 submits btc long
        _submitAndExecuteOrder(user2, 5 ether, btcLong, priceFeedDataBTC);

        // open long interest should be 15 ether
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 15 ether);
        // funding tracker should be greater than zero
        int256 fundingTracker = fundingStore.getFundingTracker(address(0), 'BTC-USD');
        assertGt(fundingTracker, 0);
    }

    function testFundingTrackerShort() public {
        // execute btc short order
        _submitAndExecuteOrder(user, 10 ether, btcShort, priceFeedDataBTC);

        // open short interest should be 10 ether
        assertEq(positionStore.getOIShort(address(0), 'BTC-USD'), 10 ether);
        // fundingStore.getLastUpdated should be block.timestamp
        assertEq(fundingStore.getLastUpdated(address(0), 'BTC-USD'), block.timestamp);

        // fast forward 1 day
        uint256 newTimestamp = block.timestamp + 1 days;
        skip(1 days);

        // get new pricefeed data to prevent stale orders
        priceFeedDataBTC = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(BTC_PRICE * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(BTC_PRICE * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            // we have to use newTimestamp here, because the compiler causes issues
            // see also https://github.com/foundry-rs/foundry/issues/1373
            uint64(newTimestamp) // publishTime
        );

        // user2 submits btc short
        _submitAndExecuteOrder(user2, 5 ether, btcShort, priceFeedDataBTC);

        // open short interest should be 15 ether
        assertEq(positionStore.getOIShort(address(0), 'BTC-USD'), 15 ether);
        // funding tracker should be less than zero
        int256 fundingTracker = fundingStore.getFundingTracker(address(0), 'BTC-USD');
        assertLt(fundingTracker, 0);
    }

    function testFundingTrackerAssetUSDC() public {
        // execute eth long order, base asset is USDC
        _submitAndExecuteOrder(user, 10000 * USDC_DECIMALS, ethLongAssetUSDC, priceFeedDataETH);

        // open long interest should be 10k USDC
        assertEq(positionStore.getOILong(address(usdc), 'ETH-USD'), 10000 * USDC_DECIMALS);
        // fundingStore.getLastUpdated should be block.timestamp
        assertEq(fundingStore.getLastUpdated(address(usdc), 'ETH-USD'), block.timestamp);

        // fast forward 1 day
        uint256 newTimestamp = block.timestamp + 1 days;
        skip(1 days);

        // get new pricefeed data to prevent stale orders
        priceFeedDataETH = pyth.createPriceFeedUpdateData(
            pythETH, // price feed ID
            int64(uint64(ETH_PRICE * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(ETH_PRICE * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            // we have to use newTimestamp here, because the compiler causes issues
            // see also https://github.com/foundry-rs/foundry/issues/1373
            uint64(newTimestamp) // publishTime
        );

        // user2 submits eth long
        _submitAndExecuteOrder(user2, 5000 * USDC_DECIMALS, ethLongAssetUSDC, priceFeedDataETH);

        // open long interest should be 15k USDC
        assertEq(positionStore.getOILong(address(usdc), 'ETH-USD'), 15000 * USDC_DECIMALS);
        // funding tracker should be greater than zero
        int256 fundingTracker = fundingStore.getFundingTracker(address(usdc), 'ETH-USD');
        assertGt(fundingTracker, 0);
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
