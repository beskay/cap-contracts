// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import './utils/Setup.t.sol';

contract FundingTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function testFundingTrackerLong() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // open long interest should be == order.size
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 10 ether);

        // fundingStore.getLastUpdated should be block.timestamp
        assertEq(fundingStore.getLastUpdated(address(0), 'BTC-USD'), block.timestamp);

        // fast forward 1 day
        skip(1 days);

        // user2 submits btc long
        _submitAndExecuteLong(user2, 5 ether);

        // open long interest should be == 10 ether + 5 ether
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 15 ether);

        // funding tracker should be greater than zero
        assertGt(fundingStore.getFundingTracker(address(0), 'BTC-USD'), 0);
    }

    function testFundingTrackerShort() public {
        // execute btc short order
        _submitAndExecuteShort(user, 10 ether);

        // open long interest should be == order.size
        assertEq(positionStore.getOIShort(address(0), 'BTC-USD'), 10 ether);

        // fundingStore.getLastUpdated should be block.timestamp
        assertEq(fundingStore.getLastUpdated(address(0), 'BTC-USD'), block.timestamp);

        // fast forward 1 day
        skip(1 days);

        // user2 submits btc long
        _submitAndExecuteShort(user2, 5 ether);

        // open long interest should be == 10 ether + 5 ether
        assertEq(positionStore.getOIShort(address(0), 'BTC-USD'), 15 ether);

        // funding tracker should be less than zero
        assertLt(fundingStore.getFundingTracker(address(0), 'BTC-USD'), 0);
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

        // get new pricefeed data to prevent stale orders
        priceFeedDataBTC = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(BTC_PRICE * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(BTC_PRICE * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        // get order id
        uint256 oid = orderStore.oid();
        orderIds[0] = oid;

        // execute order
        processor.executeOrders{value: PYTH_FEE}(orderIds, priceFeedData);
    }

    function _submitAndExecuteShort(address _user, uint256 _size) internal {
        // user submits BTC short order
        btcShort.size = _size;
        uint256 value = btcShort.margin + (btcShort.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(_user);
        orders.submitOrder{value: value}(btcShort, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // get new pricefeed data to prevent stale orders
        priceFeedDataBTC = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(BTC_PRICE * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(BTC_PRICE * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        // get order id
        uint256 oid = orderStore.oid();
        orderIds[0] = oid;

        // execute order
        processor.executeOrders{value: PYTH_FEE}(orderIds, priceFeedData);
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
