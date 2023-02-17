// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import './utils/Setup.t.sol';

contract RiskStoreTest is Setup {
    event OrderCancelled(uint256 indexed orderId, address indexed user, string reason);

    function setUp() public virtual override {
        super.setUp();

        // set pool profit limit of asset ETH to 10%
        riskStore.setPoolProfitLimit(address(0), 1000);

        // deposit 10 ether into eth pool
        pool.deposit{value: 10 ether}(address(0), 1);
    }

    function testMaxPoolDrawdown() public {
        // submit btc long
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // set BTC price to 12k USD, user made 2k USD profit
        chainlink.setMarketPrice(linkBTC, 12000 * UNIT);
        bytes memory priceFeed = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(12000 * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(12000 * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );

        // profitLimit is 10% of pool size, so 1 ether (1k USD)
        // user shouldnt be able to close unrealized profit of $2k all at once
        vm.expectEmit(true, true, true, true);
        emit OrderCancelled(2, user, '!pool-risk');
        _submitAndExecuteOrder(user, orderSize, reduceOnly, priceFeed);
    }

    function testProfitTracker() public {
        // submit btc long
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // set BTC price to 12k USD, user made 2k USD profit
        chainlink.setMarketPrice(linkBTC, 12000 * UNIT);
        bytes memory priceFeed = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(12000 * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(12000 * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );

        // profittracker should be zero
        assertEq(riskStore.getPoolProfitTracker(address(0)), 0);

        // profitLimit is 10% of pool size, so a bit more than 1 ether (1k USD) due to pool fees
        // it should be possible to close half of the position
        _submitAndExecuteOrder(user, orderSize / 2, reduceOnly, priceFeed);

        // profit tracker should be 1 ether
        assertEq(riskStore.getPoolProfitTracker(address(0)), 1 ether);

        // fast forward one day
        skip(1 days);

        // due to hourly pool decay pool profit tracker should be zero after 24 hours
        assertEq(riskStore.getPoolProfitTracker(address(0)), 0);
    }

    function testProfitTrackerNegative() public {
        // submit btc long
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // set BTC price to 9500 USD, user made 500 USD loss
        chainlink.setMarketPrice(linkBTC, 9500 * UNIT);
        bytes memory priceFeed = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(9500 * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(9500 * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );

        // profittracker should be zero
        assertEq(riskStore.getPoolProfitTracker(address(0)), 0);

        // close losing position
        _submitAndExecuteOrder(user, orderSize, reduceOnly, priceFeed);

        // profit tracker should be -0.5 ether
        assertEq(riskStore.getPoolProfitTracker(address(0)), -0.5 ether);
    }

    function testMaxOI() public {
        // set max oi to 10 ether for testing
        riskStore.setMaxOI('BTC-USD', address(0), 10 ether);

        // this should work
        uint256 orderSize = 5 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // set size of btcLong order above 5 ether
        btcLong.size = 5.01 ether;
        uint256 value = btcLong.margin + (btcLong.size * MARKET_FEE) / BPS_DIVIDER; // margin + fee

        // should revert since 5+5.01 > 10
        vm.prank(user2);
        vm.expectRevert('!max-oi');
        orders.submitOrder{value: value}(btcLong, 0, 0);
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
