// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './utils/Setup.t.sol';

contract PoolTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function testCreditTraderLoss() public {
        // submit and execute orders
        _submitAndExecuteOrders();
        // set ETH price to stop loss price
        chainlink.setMarketPrice(linkETH, ETH_SL_PRICE * UNIT);

        // execute stop loss order
        processor.selfExecuteOrder(3);

        // calculate trader loss
        int256 pnl = (int256(ethLong.size) * (int256(ETH_SL_PRICE) - int256(ETH_PRICE))) / int256(ETH_PRICE);
        uint256 absPnl = uint256(-1 * pnl);

        // poolStore.lastPaid = 0 so trader loss should have been credited to buffer
        assertEq(poolStore.getBufferBalance(address(0)), absPnl);

        // fast forward one day
        skip(1 days);

        // set BTC price to stop loss price
        chainlink.setMarketPrice(linkBTC, BTC_SL_PRICE * UNIT);

        // execute stop loss order
        processor.selfExecuteOrder(6);

        // calculate trader loss
        int256 pnl2 = (int256(btcLong.size) * (int256(BTC_SL_PRICE) - int256(BTC_PRICE))) / int256(BTC_PRICE);
        uint256 absPnl2 = uint256(-1 * pnl2);

        // part of trader loss gets sent from buffer to pool, since lastPaid != 0
        uint256 amountToSendPool = ((absPnl + absPnl2) * 1 days) / poolStore.bufferPayoutPeriod();

        assertEq(poolStore.getBufferBalance(address(0)), (absPnl + absPnl2) - amountToSendPool, '!bufferBalance');
        assertGt(poolStore.getBalance(address(0)), amountToSendPool, '!poolBalance'); // assertGt due to pool fees
    }

    function testDebitTraderProfit() public {
        // submit and execute orders
        _submitAndExecuteOrders();

        // add pool liquidity
        pool.deposit{value: 5 ether}(address(0), 1);
        // prank pool contract to increment buffer balance
        vm.prank(address(pool));
        poolStore.incrementBufferBalance(address(0), 0.3 ether);

        // balances before
        uint256 userBalanceBefore = user.balance;
        uint256 poolBalanceBefore = poolStore.getBalance(address(0));
        uint256 bufferBalanceBefore = poolStore.getBufferBalance(address(0));

        // set ETH price to take profit price
        chainlink.setMarketPrice(linkETH, ETH_TP_PRICE * UNIT);
        // execute take profit order
        processor.selfExecuteOrder(2);

        // calculate trader win
        int256 pnl = (int256(ethLong.size) * (int256(ETH_TP_PRICE) - int256(ETH_PRICE))) / int256(ETH_PRICE);

        // TP order is reduce only, fees are taken from position margin
        uint256 fee = (ethLong.size * 10) / BPS_DIVIDER;

        // user balance should be userBalanceBefore + pnl + margin - fee
        assertEq(user.balance, userBalanceBefore + uint256(pnl) + ethLong.margin - fee, '!userBalance');
        // profit should be paid out from buffer first
        assertEq(poolStore.getBufferBalance(address(0)), bufferBalanceBefore - uint256(pnl), '!bufferBalance');

        // set BTC price to take profit price
        chainlink.setMarketPrice(linkBTC, BTC_TP_PRICE * UNIT);
        // execute take profit order
        processor.selfExecuteOrder(5);

        // calculate trader win
        int256 pnl2 = (int256(btcLong.size) * (int256(BTC_TP_PRICE) - int256(BTC_PRICE))) / int256(BTC_PRICE);

        // buffer should be empty and remaining profit should be paid out from pool
        assertEq(poolStore.getBufferBalance(address(0)), 0);
        // pool balance should be a bit over 4.8 ether due to pool fees
        assertApproxEqAbs(poolStore.getBalance(address(0)), 4.8 ether, 0.001 ether);
    }

    /// @param amount amount of ETH to add and remove (Fuzzer)
    function testFuzzDepositAndWithdraw(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 10 ether);

        // Deposit
        vm.prank(user);
        pool.deposit{value: amount}(address(0), amount);

        // check balances
        assertEq(poolStore.getBalance(address(0)), amount, '!poolBalance');
        assertEq(poolStore.getUserBalance(address(0), user), amount, '!userBalance');
        assertEq(poolStore.getClpSupply(address(0)), amount, '!clpSupply');
        assertEq(poolStore.getUserClpBalance(address(0), user), amount, '!userClpBalance');

        // Withdrawing
        vm.prank(user);
        pool.withdraw(address(0), amount);

        // withdrawal fee
        uint256 feeAmount = (amount * poolStore.getWithdrawalFee(address(0))) / BPS_DIVIDER;
        uint256 amountMinusFee = amount - feeAmount;

        //user balance should be initial balance - fee
        assertEq(user.balance, INITIAL_ETH_BALANCE - feeAmount);

        // fee is left in pool
        assertEq(poolStore.getBalance(address(0)), feeAmount, '!poolBalance');

        // user balance should be zero after withdrawing
        assertEq(poolStore.getUserBalance(address(0), user), 0, '!userBalance');

        // same with CLP supply and user balance
        assertEq(poolStore.getClpSupply(address(0)), 0, '!clpSupply');
        assertEq(poolStore.getUserClpBalance(address(0), user), 0, '!userClpBalance');
    }

    /// @param amount amount of USDC to add and remove (Fuzzer)
    function testFuzzDepositAndWithdrawUSDC(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 100_000 * USDC_DECIMALS);

        // Deposit
        vm.prank(user);
        pool.deposit(address(usdc), amount);

        // check balances
        assertEq(poolStore.getBalance(address(usdc)), amount, '!poolBalance');
        assertEq(poolStore.getUserBalance(address(usdc), user), amount, '!userBalance');
        assertEq(poolStore.getClpSupply(address(usdc)), amount, '!clpSupply');
        assertEq(poolStore.getUserClpBalance(address(usdc), user), amount, '!userClpBalance');

        // Withdrawing
        vm.prank(user);
        pool.withdraw(address(usdc), amount);

        // withdrawal fee
        uint256 feeAmount = (amount * poolStore.getWithdrawalFee(address(usdc))) / BPS_DIVIDER;
        uint256 amountMinusFee = amount - feeAmount;

        // user balance should be initial balance - fee
        assertEq(usdc.balanceOf(user), INITIAL_USDC_BALANCE - feeAmount);

        // fee is left in pool
        assertEq(poolStore.getBalance(address(usdc)), feeAmount, '!poolBalance');

        // user balance should be zero after withdrawing
        assertEq(poolStore.getUserBalance(address(usdc), user), 0, '!userBalance');

        // same with CLP supply and user balance
        assertEq(poolStore.getClpSupply(address(usdc)), 0, '!clpSupply');
        assertEq(poolStore.getUserClpBalance(address(usdc), user), 0, '!userClpBalance');
    }

    // utils
    function _submitAndExecuteOrders() internal {
        vm.startPrank(user);

        // submit two orders with SL and TP
        uint256 value = ethLong.margin + (ethLong.size * 10) / BPS_DIVIDER; // margin + fee
        orders.submitOrder{value: value}(ethLong, ETH_TP_PRICE * UNIT, ETH_SL_PRICE * UNIT);

        value = btcLong.margin + (btcLong.size * 10) / BPS_DIVIDER;
        orders.submitOrder{value: value}(btcLong, BTC_TP_PRICE * UNIT, BTC_SL_PRICE * UNIT);

        vm.stopPrank();

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](2);
        priceFeedData[0] = priceFeedDataETH;
        priceFeedData[1] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](2);
        orderIds[0] = 1;
        orderIds[1] = 4;

        // execute market orders
        processor.executeOrders(orderIds, priceFeedData);

        // make sure market orders are executed
        assertEq(orderStore.getMarketOrderCount(), 0);

        // fast forward 5 minutes so self execution of orders works
        skip(300);

        // orders left at this point:
        // orderId 2 -> ethLong TP
        // orderId 3 -> ethLong SL
        // orderId 5 -> btcLong TP
        // orderId 6 -> btcLong SL
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
