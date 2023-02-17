// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import './utils/Setup.t.sol';

contract PositionsTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function testIncreasePosition() public {
        // execute btc long order
        _submitAndExecuteOrder(user, 10 ether, btcLong, priceFeedDataBTC);

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
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // open long interest should be == order.size
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 10 ether, '!oiLong');

        uint256 userBalanceBefore = user.balance;
        // close half of open long position
        _submitAndExecuteOrder(user, orderSize / 2, btcShort, priceFeedDataBTC);

        // half of margin should be transferred back to user (minus fee of short order)
        uint256 shortOrderFee = ((orderSize / 2) * MARKET_FEE) / BPS_DIVIDER;
        assertEq(user.balance, userBalanceBefore + btcLong.margin / 2 - shortOrderFee);

        // open long interest should be half of initial interest
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 5 ether, '!oiLong');

        // Size of long position should be half of initial size
        PositionStore.Position[] memory userPos = positionStore.getUserPositions(user);
        assertEq(userPos[0].size, orderSize / 2);

        // submit short with size > existing position size
        // long position should be closed completely
        // and short position with size == 5 ether should be opened
        _submitAndExecuteOrder(user, orderSize, btcShort, priceFeedDataBTC);

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
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // open long interest should be == order.size
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), orderSize, '!oiLong');

        uint256 userBalanceBefore = user.balance;

        // close open long position
        _submitAndExecuteOrder(user, orderSize, reduceOnly, priceFeedDataBTC);

        // margin should be transferred back to user (minus fee of reduce only order)
        uint256 reduceOnlyFee = (orderSize * MARKET_FEE) / BPS_DIVIDER;
        assertEq(user.balance, userBalanceBefore + btcLong.margin - reduceOnlyFee);

        // open long interest should be zero
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), 0, '!oiLong');

        // Position should be closed
        PositionStore.Position[] memory userPos = positionStore.getUserPositions(user);
        assertEq(userPos.length, 0);
    }

    function testClosePositionWithoutProfit() public {
        // execute btc long order
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // open long interest should be == order.size
        assertEq(positionStore.getOILong(address(0), 'BTC-USD'), orderSize, '!oiLong');

        uint256 userBalanceBefore = user.balance;

        vm.prank(user);
        positions.closePositionWithoutProfit(address(0), 'BTC-USD');

        // margin should be transferred back to user
        assertEq(user.balance, userBalanceBefore + btcLong.margin);
    }

    function testRevertClosePositionWithoutProfit() public {
        // execute btc long order
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // decrease BTC price so pnl of position is < 0
        chainlink.setMarketPrice(linkBTC, BTC_PRICE + 1000 * UNIT);

        vm.prank(user);
        vm.expectRevert('!pnl-positive');
        positions.closePositionWithoutProfit(address(0), 'BTC-USD');
    }

    function testAddMargin() public {
        // execute btc long order
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

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
        uint256 orderSize = 5000 * USDC_DECIMALS;
        _submitAndExecuteOrder(user, orderSize, btcLongAssetUSDC, priceFeedDataBTC);

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
        uint256 orderSize = 5 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // revert due to min leverage
        vm.prank(user);
        vm.expectRevert('!min-leverage');
        positions.addMargin{value: orderSize}(address(0), 'BTC-USD', 0.1 ether);

        // revert due to margin == 0
        vm.prank(user);
        vm.expectRevert('!margin');
        positions.addMargin{value: 0}(address(0), 'BTC-USD', 0.1 ether);
    }

    function testRemoveMargin() public {
        // execute btc long order
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

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
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

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
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user, orderSize, btcLong, priceFeedDataBTC);

        // calculate fees
        uint256 fee = (orderSize * MARKET_FEE) / BPS_DIVIDER;
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;

        uint256 netFee = fee - keeperFee;

        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToPool = (netFee * poolStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToTreasury = netFee - feeToStaking - feeToPool;

        // validate fee payment
        assertEq(poolStore.getBalance(address(0)), feeToPool, '!feeToPool');
        assertEq(stakingStore.getPendingReward(address(0)), feeToStaking, '!feeToStaking');
        assertEq(treasury.balance, feeToTreasury, '!feeToTreasury');
        assertEq(user3.balance, INITIAL_ETH_BALANCE + keeperFee - PYTH_FEE, '!keeperFee');
    }

    function testCreditFeeAssetUSDC() public {
        // execute btc long order
        uint256 orderSize = 5000 * USDC_DECIMALS;
        _submitAndExecuteOrder(user, orderSize, btcLongAssetUSDC, priceFeedDataBTC);

        // calculate fees
        uint256 fee = (orderSize * MARKET_FEE) / BPS_DIVIDER;
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;

        uint256 netFee = fee - keeperFee;

        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToPool = (netFee * poolStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToTreasury = netFee - feeToStaking - feeToPool;

        // validate fee payment
        assertEq(poolStore.getBalance(address(usdc)), feeToPool, '!feeToPool');
        assertEq(stakingStore.getPendingReward(address(usdc)), feeToStaking, '!feeToStaking');
        assertEq(usdc.balanceOf(treasury), feeToTreasury, '!feeToTreasury');
        assertEq(usdc.balanceOf(user3), INITIAL_USDC_BALANCE + keeperFee, '!keeperFee');
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
