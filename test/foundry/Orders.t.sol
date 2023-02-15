// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import './utils/Setup.t.sol';

contract OrderTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function testSubmitOrder() public {
        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        orders.submitOrder{value: value}(ethLong, 0, 0);

        // order should be registered
        assertEq(orderStore.getUserOrderCount(user), 1);
        assertEq(orderStore.getMarketOrderCount(), 1);

        // Margin + fee should be transferred in
        assertEq(address(fundStore).balance, value);
    }

    function testSubmitOrderAssetUSDC() public {
        uint256 value = btcLongAssetUSDC.margin + (btcLongAssetUSDC.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        orders.submitOrder(btcLongAssetUSDC, 0, 0);

        // order should be registered
        assertEq(orderStore.getUserOrderCount(user), 1);
        assertEq(orderStore.getMarketOrderCount(), 1);

        // Margin + fee should be transferred in
        assertEq(usdc.balanceOf(address(fundStore)), value);
    }

    function testSubmitTPSLOrder() public {
        uint256 value = btcLong.margin + (btcLong.size * 10) / BPS_DIVIDER; // margin + fee

        // set expiry for testing
        btcLong.expiry = block.timestamp + 100;

        vm.prank(user);
        orders.submitOrder{value: value}(btcLong, BTC_TP_PRICE, BTC_SL_PRICE);

        // orders should be registered
        assertEq(orderStore.getUserOrderCount(user), 3);
        assertEq(orderStore.getMarketOrderCount(), 1);
        assertEq(orderStore.getTriggerOrderCount(), 2);

        // Margin + fee should be transferred in
        assertEq(address(fundStore).balance, value);

        OrderStore.Order[] memory userOrders = orderStore.getUserOrders(user);

        // check expiry
        assertEq(userOrders[0].expiry, block.timestamp + 100);
        assertEq(userOrders[1].expiry, 0);
        assertEq(userOrders[2].expiry, 0);

        // check isLong
        assertEq(userOrders[0].isLong, true);
        assertEq(userOrders[1].isLong, false);
        assertEq(userOrders[2].isLong, false);
    }

    function testCancelOrder() public {
        uint256 userBalanceBefore = user.balance;
        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        orders.submitOrder{value: value}(ethLong, 0, 0);

        // Margin + fee should be transferred in
        assertEq(address(fundStore).balance, value);

        // cancel order
        vm.prank(user);
        orders.cancelOrder(1);

        // Margin + fee should be transferred out again
        assertEq(address(fundStore).balance, 0);
        // user balance should be same as before
        assertEq(user.balance, userBalanceBefore);

        // no orders
        assertEq(orderStore.getUserOrderCount(user), 0);
        assertEq(orderStore.getMarketOrderCount(), 0);
    }

    function testCancelOrderUSDC() public {
        uint256 userBalanceBefore = usdc.balanceOf(user);
        uint256 value = btcLongAssetUSDC.margin + (btcLongAssetUSDC.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        orders.submitOrder(btcLongAssetUSDC, 0, 0);

        // Margin + fee should be transferred in
        assertEq(usdc.balanceOf(address(fundStore)), value);

        // cancel order
        vm.prank(user);
        orders.cancelOrder(1);

        // Margin + fee should be transferred out again
        assertEq(usdc.balanceOf(address(fundStore)), 0);
        // user balance should be same as before
        assertEq(usdc.balanceOf(user), userBalanceBefore);

        // no orders
        assertEq(orderStore.getUserOrderCount(user), 0);
        assertEq(orderStore.getMarketOrderCount(), 0);
    }

    function testRevertValue() public {
        vm.prank(user);
        vm.expectRevert();
        orders.submitOrder{value: 0}(ethLong, 0, 0);
    }

    function testRefundMsgValueExcess() public {
        uint256 userBalanceBefore = user.balance;
        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        // user submits order and sends 10 ether with it
        vm.prank(user);
        orders.submitOrder{value: 10 ether}(ethLong, 0, 0);

        // order should be registered
        assertEq(orderStore.getUserOrderCount(user), 1);
        assertEq(orderStore.getMarketOrderCount(), 1);

        // msg.value excess should have been refunded
        assertEq(user.balance, userBalanceBefore - value);
    }

    function testRevertBelowMinSize() public {
        ethLong.size = 0.001 ether;

        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        vm.expectRevert('!min-size');
        orders.submitOrder{value: value}(ethLong, 0, 0);
    }

    function testRevertUnsupportedAsset() public {
        // unsupported asset
        ethLong.asset = address(0x000000000000000000000000000000000000dEaD);

        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        vm.expectRevert('!asset-exists');
        orders.submitOrder{value: value}(ethLong, 0, 0);
    }

    function testRevertBelowMinLeverage() public {
        // min leverage = 1, submitting order with size below margin should fail
        ethLong.size = ethLong.margin - 1;

        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        vm.expectRevert('!min-leverage');
        orders.submitOrder{value: value}(ethLong, 0, 0);
    }

    function testRevertAboveMaxLeverage() public {
        // set leverage to 1000
        ethLong.size = ethLong.margin * 1000;

        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        vm.expectRevert('!max-leverage');
        orders.submitOrder{value: value}(ethLong, 0, 0);
    }

    function testRevertExpiry() public {
        // should revert if block.timestamp > order.expiry
        ethLong.expiry = block.timestamp - 1;

        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        vm.expectRevert('!expiry-value');
        orders.submitOrder{value: value}(ethLong, 0, 0);

        // should revert if order.expiry > maxMarketOrderTTL
        btcLongAssetUSDC.expiry = block.timestamp + orderStore.maxMarketOrderTTL() + 1;

        vm.prank(user);
        vm.expectRevert('!max-expiry');
        orders.submitOrder(btcLongAssetUSDC, 0, 0);

        // should revert if order.expiry > maxTriggerOrderTTL for limit orders
        ethLimitLong.expiry = block.timestamp + orderStore.maxTriggerOrderTTL() + 1;

        vm.prank(user);
        vm.expectRevert('!max-expiry');
        orders.submitOrder{value: value}(ethLimitLong, 0, 0);
    }

    function testReverTPBelowSLPrice() public {
        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee

        vm.prank(user);
        vm.expectRevert('!tpsl-invalid');
        orders.submitOrder{value: value}(ethLong, 950 * UNIT, 1050 * UNIT);
    }

    function testRevertOrdersPaused() public {
        orderStore.setAreNewOrdersPaused(true);

        vm.prank(user);
        vm.expectRevert('!paused');
        orders.submitOrder(btcLongAssetUSDC, 0, 0);
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
