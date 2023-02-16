// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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

        // margin should be transferred back to user
        uint256 fee = (btcLong.size * 10) / BPS_DIVIDER;
        assertEq(user.balance, userBalanceBefore + btcLong.margin);
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

    function testAddMargin() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        uint256 userBalanceBefore = user.balance;
        uint256 fundStoreBalanceBefore = address(fundStore).balance;

        uint256 marginToAdd = 0.5 ether;

        vm.prank(user);
        // Margin in function argument doesnt matter in that case, since margin = msg.value when asset is ETH
        positions.addMargin{value: marginToAdd}(address(0), 'BTC-USD', 0.1 ether);

        // Margin should be transferred in
        assertEq(user.balance, userBalanceBefore - marginToAdd);
        assertEq(address(fundStore).balance, fundStoreBalanceBefore + marginToAdd);
    }

    function testAddMarginUSDC() public {
        // execute btc long order
        _submitAndExecuteLongAssetUSDC(user, 5000 * USDC_DECIMALS);

        uint256 userBalanceBefore = usdc.balanceOf(user);
        uint256 fundStoreBalanceBefore = usdc.balanceOf(address(fundStore));

        uint256 marginToAdd = 500 * USDC_DECIMALS;

        vm.prank(user);
        positions.addMargin(address(usdc), 'BTC-USD', marginToAdd);

        // Margin should be transferred in
        // Margin in function argument doesnt matter in that case, since margin = msg.value when asset is ETH
        assertEq(usdc.balanceOf(user), userBalanceBefore - marginToAdd);
        assertEq(usdc.balanceOf(address(fundStore)), fundStoreBalanceBefore + marginToAdd);
    }

    function testRevertAddMargin() public {
        // execute btc long order
        _submitAndExecuteLong(user, 5 ether);

        // revert due to min leverage
        vm.prank(user);
        vm.expectRevert('!min-leverage');
        positions.addMargin{value: btcLong.size}(address(0), 'BTC-USD', 0.1 ether);

        // revert due to margin == 0
        vm.prank(user);
        vm.expectRevert('!margin');
        positions.addMargin{value: 0}(address(0), 'BTC-USD', 0.1 ether);
    }

    function testRemoveMargin() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // margin of btc long order is 1 eth

        uint256 userBalanceBefore = user.balance;
        uint256 fundStoreBalanceBefore = address(fundStore).balance;

        uint256 marginToRemove = 0.5 ether;

        vm.prank(user);
        positions.removeMargin(address(0), 'BTC-USD', marginToRemove);

        // Margin should be transferred out
        assertEq(user.balance, userBalanceBefore + marginToRemove);
        assertEq(address(fundStore).balance, fundStoreBalanceBefore - marginToRemove);
    }

    function testRevertRemoveMargin() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // should revert when trying to remove more than existing margin
        vm.prank(user);
        vm.expectRevert('!margin');
        positions.removeMargin(address(0), 'BTC-USD', btcLong.margin + 1);

        // should revert when max lev is exceeded
        vm.prank(user);
        vm.expectRevert('!max-leverage');
        positions.removeMargin(address(0), 'BTC-USD', btcLong.margin - 1);

        // should revert when unrealized loss of position is greater than remainingMargin * removeMarginBuffer

        chainlink.setMarketPrice(linkBTC, 9500 * UNIT);

        // upl of position is -0.5 ether, margin is 1 ether
        // due to removeMarginBuffer removing 0.5 ether should fail
        vm.prank(user);
        vm.expectRevert();
        positions.removeMargin(address(0), 'BTC-USD', 0.5 ether);
    }

    function testCreditFee() public {
        // execute btc long order
        _submitAndExecuteLong(user, 10 ether);

        // calculate fees
        uint256 fee = (btcLong.size * 10) / BPS_DIVIDER;
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;

        uint256 netFee = fee - keeperFee;

        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToPool = (netFee * poolStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToTreasury = netFee - feeToStaking - feeToPool;

        // validate fee payment
        assertEq(poolStore.getBalance(address(0)), feeToPool, '!feeToPool');
        assertEq(stakingStore.getPendingReward(address(0)), feeToStaking, '!feeToStaking');
        assertEq(treasury.balance, feeToTreasury, '!feeToTreasury');
        assertEq(user2.balance, INITIAL_ETH_BALANCE + keeperFee - PYTH_FEE, '!keeperFee');
    }

    function testCreditFeeAssetUSDC() public {
        // execute btc long order
        _submitAndExecuteLongAssetUSDC(user, 5000 * USDC_DECIMALS);

        // calculate fees
        uint256 fee = (btcLongAssetUSDC.size * 10) / BPS_DIVIDER;
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;

        uint256 netFee = fee - keeperFee;

        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToPool = (netFee * poolStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToTreasury = netFee - feeToStaking - feeToPool;

        // validate fee payment
        assertEq(poolStore.getBalance(address(usdc)), feeToPool, '!feeToPool');
        assertEq(stakingStore.getPendingReward(address(usdc)), feeToStaking, '!feeToStaking');
        assertEq(usdc.balanceOf(treasury), feeToTreasury, '!feeToTreasury');
        assertEq(usdc.balanceOf(user2), INITIAL_USDC_BALANCE + keeperFee, '!keeperFee');
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

        // set keeper to user2, to test fees in {testCreditFees}
        vm.prank(user2);
        processor.executeOrders{value: PYTH_FEE}(orderIds, priceFeedData);
    }

    function _submitAndExecuteLongAssetUSDC(address _user, uint256 _size) internal {
        // user submits BTC long order
        btcLongAssetUSDC.size = _size;
        uint256 value = btcLongAssetUSDC.margin + (btcLongAssetUSDC.size * 10) / BPS_DIVIDER; // margin + fee
        vm.prank(_user);
        orders.submitOrder(btcLongAssetUSDC, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        // get order id
        uint256 oid = orderStore.oid();
        orderIds[0] = oid;

        // set keeper to user2, to test fees in {testCreditFeesUSDC}
        vm.prank(user2);
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
        processor.executeOrders{value: PYTH_FEE}(orderIds, priceFeedData);
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
