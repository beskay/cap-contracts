// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './utils/Setup.t.sol';

contract PositionsTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function testIncreasePosition() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // open long interest should be == order.size
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 10 ether, '!oiLong');

        // validate position
        PositionStore.Position[] memory userPos = positionStore.getUserPositions(user);
        assertEq(userPos[0].size, 10 ether);

        // order should be removed
        assertEq(orderStore.getUserOrderCount(user), 0);
    }

    function testDecreasePosition() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // open long interest should be == order.size
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 10 ether, '!oiLong');

        uint256 userBalanceBefore = user.balance;
        // close half of open long position
        _submitAndExecuteShort(user, 5 ether);

        // half of margin should be transferred back to user (minus fee of short order)
        uint256 shortOrderFee = (btcShort.size * 10) / BPS_DIVIDER;
        assertEq(user.balance, userBalanceBefore + btcLong.margin / 2 - shortOrderFee);

        // open long interest should be half of initial interest
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 5 ether, '!oiLong');

        // Size of long position should be half of initial size
        PositionStore.Position[] memory userPos = positionStore.getUserPositions(user);
        assertEq(userPos[0].size, 5 ether);

        // submit short with size > existing position size
        // long position should be closed completely
        // and short position with size == 5 ether should be opened
        _submitAndExecuteShort(user, 10 ether);

        userPos = positionStore.getUserPositions(user);

        // userPos should be a short position now
        assertEq(userPos[0].isLong, false);
        // size should be 5 ether
        assertEq(userPos[0].size, 5 ether);

        // open long interest should be zero
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 0, '!oiLong');
        // open short interest should be 5 ether
        assertEq(positionStore.getOIShort(address(0), 'BTC-USD'), 5 ether, '!oiShort');
    }

    function testDecreasePositionReduceOnly() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // open long interest should be == order.size
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 10 ether, '!oiLong');

        uint256 userBalanceBefore = user.balance;
        // close open long position
        _submitAndExecuteReduceOnly(user, 10 ether);

        // margin should be transferred back to user (minus fee of reduce only order)
        uint256 reduceOnlyFee = (reduceOnly.size * 10) / BPS_DIVIDER;
        assertEq(user.balance, userBalanceBefore + btcLong.margin - reduceOnlyFee);

        // open long interest should be zero
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 0, '!oiLong');

        // Position should be closed
        PositionStore.Position[] memory userPos = positionStore.getUserPositions(user);
        assertEq(userPos.length, 0);
    }

    function testClosePositionWithoutProfit() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // open long interest should be == order.size
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 10 ether, '!oiLong');

        uint256 userBalanceBefore = user.balance;

        vm.prank(user);
        positions.closePositionWithoutProfit(address(0), 'BTC-USD');

        // margin should be transferred back to user (minus fee)
        uint256 fee = (btcLong.size * 10) / BPS_DIVIDER;
        assertEq(user.balance, userBalanceBefore + btcLong.margin - fee);
    }

    function testRevertClosePositionWithoutProfit() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // decrease BTC price so pnl of position is < 0
        chainlink.setMarketPrice(linkBTC, BTC_PRICE + 1000 * UNIT);

        vm.prank(user);
        vm.expectRevert('!pnl-positive');
        positions.closePositionWithoutProfit(address(0), 'BTC-USD');
    }

    function testAddMargin() public {}

    function testAddMarginUSDC() public {}

    function testRemoveMargin() public {}

    /*
    function testCreditFee() public {
        // ETH and BTC Long are executed, position size is 10k each, fee is 10 USDC each
        uint256 fee = _getOrderFee('ETH-USD', ethLong.size) + _getOrderFee('BTC-USD', btcLong.size);
        uint256 keeperFee = (fee * store.keeperFeeShare()) / BPS_DIVIDER;
        fee -= keeperFee;
        uint256 poolFee = (fee * store.poolFeeShare()) / BPS_DIVIDER;
        uint256 treasuryFee = fee - poolFee;

        assertEq(store.poolBalance(), poolFee, '!poolFee');
        assertEq(IERC20(usdc).balanceOf(treasury), treasuryFee, '!treasuryFee');
        assertEq(store.getBalance(address(this)), keeperFee, '!keeperFee');
    }

    */

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

    function _submitAndExecuteShort(address _user, uint256 _size) internal {
        // user submits BTC short order
        btcShort.size = _size;
        uint256 value = btcShort.margin + (btcShort.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(_user);
        orders.submitOrder{value: value}(btcShort, 0, 0);

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

    function _submitAndExecuteReduceOnly(address _user, uint256 _size) internal {
        // user submits BTC short order
        reduceOnly.size = _size;
        vm.prank(_user);
        orders.submitOrder(reduceOnly, 0, 0);

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

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
