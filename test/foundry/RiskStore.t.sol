// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
        _submitAndExecuteLong(user, 10 ether);

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
        _submitAndExecuteReduceOnly(user, btcLong.size, priceFeed);
    }

    function testProfitTracker() public {
        // submit btc long
        _submitAndExecuteLong(user, 10 ether);

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
        _submitAndExecuteReduceOnly(user, btcLong.size / 2, priceFeed);

        // profit tracker should be 1 ether
        assertEq(riskStore.getPoolProfitTracker(address(0)), 1 ether);

        // fast forward one day
        skip(1 days);

        // due to hourly pool decay pool profit tracker should be zero after 24 hours
        assertEq(riskStore.getPoolProfitTracker(address(0)), 0);
    }

    function testProfitTrackerNegative() public {
        // submit btc long
        _submitAndExecuteLong(user, 10 ether);

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

        // profitLimit is 10% of pool size, so a bit more than 1 ether (1k USD) due to pool fees
        // it should be possible to close half of the position
        _submitAndExecuteReduceOnly(user, btcLong.size, priceFeed);

        // profit tracker should be -0.5 ether
        assertEq(riskStore.getPoolProfitTracker(address(0)), -0.5 ether);
    }

    function testMaxOI() public {
        // set max oi to 10 ether for testing
        riskStore.setMaxOI('BTC-USD', address(0), 10 ether);

        // this should work
        _submitAndExecuteLong(user, 5 ether);

        btcLong.size = 5.01 ether;
        uint256 value = btcLong.margin + (btcLong.size * 10) / BPS_DIVIDER; // margin + fee

        // should revert
        vm.prank(user2);
        vm.expectRevert('!max-oi');
        orders.submitOrder{value: value}(btcLong, 0, 0);
    }

    // utils
    function _submitAndExecuteLong(address _user, uint256 _size) internal {
        // user submits BTC long order
        btcLong.size = _size;
        uint256 value = btcLong.margin + (btcLong.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(_user);
        orders.submitOrder{value: value}(btcLong, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        // get order id
        uint256 oid = orderStore.oid();
        orderIds[0] = oid;

        // execute order
        processor.executeOrders(orderIds, priceFeedData);
    }

    function _submitAndExecuteReduceOnly(address _user, uint256 _size, bytes memory _priceFeedData) internal {
        // user submits BTC short order
        reduceOnly.size = _size;
        vm.prank(_user);
        orders.submitOrder(reduceOnly, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = _priceFeedData;
        uint256[] memory orderIds = new uint256[](1);
        // get order id
        uint256 oid = orderStore.oid();
        orderIds[0] = oid;

        // execute order
        processor.executeOrders(orderIds, priceFeedData);
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
