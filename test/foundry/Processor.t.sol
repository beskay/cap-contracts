// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './utils/Setup.t.sol';

contract ProcessorTest is Setup {
    // Events
    event OrderCancelled(uint256 indexed orderId, address indexed user, string reason);
    event PositionLiquidated(
        address indexed user,
        address indexed asset,
        string market,
        bool isLong,
        uint256 size,
        uint256 margin,
        uint256 marginUsd,
        uint256 price,
        uint256 fee
    );
    event OrderSkipped(uint256 indexed orderId, string market, uint256 price, uint256 publishTime, string reason);

    function setUp() public virtual override {
        super.setUp();
    }

    function testExecuteMarketOrder() public {
        // user submits BTC long order
        uint256 value = btcLong.margin + (btcLong.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(btcLong, 0, 0);

        // user2 submits ETH short order
        value = ethShort.margin + (ethShort.size * 10) / BPS_DIVIDER;
        vm.prank(user2);
        orders.submitOrder{value: value}(ethShort, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](2);
        priceFeedData[0] = priceFeedDataETH;
        priceFeedData[1] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](2);
        orderIds[0] = 1;
        orderIds[1] = 2;

        // execute market orders
        processor.executeOrders{value: 0.01 ether}(orderIds, priceFeedData);

        // market orders should be executed
        assertEq(orderStore.getMarketOrderCount(), 0, '!marketOrderCount');
    }

    function testExecuteLimitOrder() public {
        // user submits ETH limit short
        uint256 value = ethLimitShort.margin + (ethLimitShort.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(ethLimitShort, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // set price above order price
        chainlink.setMarketPrice(linkETH, 1200 * UNIT);
        priceFeedDataETH = pyth.createPriceFeedUpdateData(
            pythETH, // price feed ID
            int64(uint64(1200 * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(1200 * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataETH;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // execute order
        processor.executeOrders(orderIds, priceFeedData);

        // limit order should be executed
        assertEq(orderStore.getTriggerOrderCount(), 0, '!triggerOrderCount');
    }

    function testExecuteStopOrder() public {
        // user submits ETH limit short
        uint256 value = ethStopShort.margin + (ethStopShort.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(ethStopShort, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // set price below order price
        chainlink.setMarketPrice(linkETH, 800 * UNIT);
        priceFeedDataETH = pyth.createPriceFeedUpdateData(
            pythETH, // price feed ID
            int64(uint64(800 * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(800 * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataETH;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // execute order
        processor.executeOrders(orderIds, priceFeedData);

        // stop order should be executed
        assertEq(orderStore.getTriggerOrderCount(), 0, '!triggerOrderCount');
    }

    function testSelfExecuteOrder() public {
        // user submits ETH stop long order
        uint256 value = ethStopLong.margin + (ethStopLong.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(ethStopLong, 0, 0);

        // fast forward 5 minutes so self execution of order with chainlink works
        skip(300);

        // at this point price is below trigger price of stop long order, shouldnt execute
        processor.selfExecuteOrder(1);
        assertEq(orderStore.getTriggerOrderCount(), 1, '!triggerOrderCount');

        // set chainlink price to trigger price of stop long order, this time it should execute
        chainlink.setMarketPrice(linkETH, ethStopLong.price);
        processor.selfExecuteOrder(1);

        // trigger order should be executed
        assertEq(orderStore.getTriggerOrderCount(), 0, '!triggerOrderCount');
    }

    function testCancelReduceOnlyOrder() public {
        // user submits a reduce only order without any open positions
        vm.prank(user);
        orders.submitOrder(reduceOnly, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // should cancel order
        vm.expectEmit(true, true, true, true);
        emit OrderCancelled(1, user, '!reduce');
        processor.executeOrders(orderIds, priceFeedData);
    }

    function testProtectedOrder() public {
        // protected order when orderType == 0 and price != 0
        // set order price 10 USD below market price
        ethLong.price = 990 * UNIT;

        // user submits order
        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(ethLong, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataETH;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // should cancel protected market order
        vm.expectEmit(true, true, true, true);
        emit OrderCancelled(1, user, '!protected');
        processor.executeOrders(orderIds, priceFeedData);
    }

    function testLiquidatePosition() public {
        // user submits BTC long order
        uint256 fee = (btcLong.size * 10) / BPS_DIVIDER;
        uint256 value = btcLong.margin + fee; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(btcLong, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // execute order
        processor.executeOrders(orderIds, priceFeedData);

        // BTC crashes 50%, liquidating open btc long position
        chainlink.setMarketPrice(linkBTC, 5000 * UNIT);

        priceFeedDataBTC = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(5000 * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(5000 * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );

        // function arguments
        priceFeedData[0] = priceFeedDataBTC;
        address[] memory userArray = new address[](1);
        userArray[0] = user;
        address[] memory assetArray = new address[](1);
        assetArray[0] = address(0);
        string[] memory marketArray = new string[](1);
        marketArray[0] = 'BTC-USD';

        // should liquidate position
        vm.expectEmit(true, true, true, true);
        emit PositionLiquidated(
            user,
            address(0),
            'BTC-USD',
            true,
            btcLong.size,
            btcLong.margin,
            1000 * UNIT,
            5000 * UNIT,
            fee
        );
        processor.liquidatePositions{value: 0.01 ether}(userArray, assetArray, marketArray, priceFeedData);
    }

    function testSelfLiquidatePosition() public {
        // user submits BTC long order
        uint256 fee = (btcLong.size * 10) / BPS_DIVIDER;
        uint256 value = btcLong.margin + fee; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(btcLong, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // execute order
        processor.executeOrders(orderIds, priceFeedData);

        // BTC crashes 50%, liquidating open btc long position
        chainlink.setMarketPrice(linkBTC, 5000 * UNIT);

        // should liquidate position
        vm.expectEmit(true, true, true, true);
        emit PositionLiquidated(
            user,
            address(0),
            'BTC-USD',
            true,
            btcLong.size,
            btcLong.margin,
            1000 * UNIT,
            5000 * UNIT,
            fee
        );
        processor.selfLiquidatePosition(user, address(0), 'BTC-USD');
    }

    function testSkipOrderTooEarly() public {
        // user submits BTC long order
        uint256 fee = (btcLong.size * 10) / BPS_DIVIDER;
        uint256 value = btcLong.margin + fee; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(btcLong, 0, 0);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // executing order before market.minOrderAge passed, should be skipped
        vm.expectEmit(true, true, true, true);
        emit OrderSkipped(1, 'BTC-USD', 0, 0, '!early');
        processor.executeOrders(orderIds, priceFeedData);
    }

    function testSkipOrderStale() public {
        // user submits BTC long order
        uint256 fee = (btcLong.size * 10) / BPS_DIVIDER;
        uint256 value = btcLong.margin + fee; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(btcLong, 0, 0);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // order execution based on price feed data older than market.pythMaxAge should be skipped
        skip(21); // market.pythMaxAge = 20

        vm.expectEmit(true, true, true, true);
        emit OrderSkipped(1, 'BTC-USD', 10000 * UNIT, block.timestamp - 21, '!stale');
        processor.executeOrders(orderIds, priceFeedData);
    }

    function testChainlinkDeviation() public {
        // user submits BTC long order
        uint256 value = btcLong.margin + (btcLong.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(user);
        orders.submitOrder{value: value}(btcLong, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        orderIds[0] = 1;

        // set chainlink price 10% below pyth price (max deviation is 5%)
        chainlink.setMarketPrice(linkBTC, 9000 * UNIT);

        // execute orders
        processor.executeOrders(orderIds, priceFeedData);

        // order shouldnt be executed due to price deviation
        assertEq(orderStore.getUserOrderCount(user), 1, '!userOrderCount');
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
