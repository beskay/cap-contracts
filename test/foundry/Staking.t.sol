// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import './utils/Setup.t.sol';

contract StakingTest is Setup {
    // Events
    event CAPStaked(address indexed user, uint256 amount);
    event CAPUnstaked(address indexed user, uint256 amount);
    event CollectedReward(address indexed user, address indexed asset, uint256 amount);

    function setUp() public virtual override {
        super.setUp();
    }

    function testCollectReward() public {
        // user stakes 750 CAP
        vm.prank(user);
        staking.stake(750 * UNIT);

        // user2 stakes 250 CAP
        vm.prank(user2);
        staking.stake(250 * UNIT);

        // user3 submits order, incurring a fee which is distributed to stakers
        uint256 feeInETH = _submitAndExecuteOrder(user3, 10 ether);

        // user3 stakes after orders are executed
        vm.prank(user3);
        staking.stake(500 * UNIT);

        // user and user2 should receive staking rewards, user3 should receive nothing
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CollectedReward(user, address(0), (feeInETH * 3) / 4);
        staking.collectReward(address(0));

        vm.prank(user2);
        vm.expectEmit(true, true, true, true);
        emit CollectedReward(user2, address(0), feeInETH / 4);
        staking.collectReward(address(0));

        uint256 balanceBefore = user3.balance;
        vm.prank(user3);
        staking.collectReward(address(0));
        assertEq(balanceBefore, user3.balance);
    }

    function testCollectRewardUSDC() public {
        // user stakes 750 CAP
        vm.prank(user);
        staking.stake(750 * UNIT);

        // user2 stakes 250 CAP
        vm.prank(user2);
        staking.stake(250 * UNIT);

        // user3 submits order, incurring a fee which is distributed to stakers
        uint256 feeInUSDC = _submitAndExecuteOrderAssetUSDC(user3, 5000 * USDC_DECIMALS);

        // user3 stakes after orders are executed
        vm.prank(user3);
        staking.stake(500 * UNIT);

        // user and user2 should receive staking rewards, user3 should receive nothing

        // user
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        vm.prank(user);
        staking.collectReward(address(usdc));
        // rounding error of around 0.2% depending on total staked supply and pendingReward
        assertApproxEqRel(usdc.balanceOf(user) - usdcBalanceBefore, (feeInUSDC * 3) / 4, 0.003e18);

        // user2
        usdcBalanceBefore = usdc.balanceOf(user2);
        vm.prank(user2);
        staking.collectReward(address(usdc));
        // rounding error of around 0.2% depending on total staked supply and pendingReward
        assertApproxEqRel(usdc.balanceOf(user2) - usdcBalanceBefore, feeInUSDC / 4, 0.003e18);

        // user3 should receive nothing
        usdcBalanceBefore = usdc.balanceOf(user3);
        vm.prank(user3);
        staking.collectReward(address(usdc));
        assertEq(usdcBalanceBefore, usdc.balanceOf(user3));
    }

    function testCollectMultiple() public {
        // user stakes 750 CAP
        vm.prank(user);
        staking.stake(750 * UNIT);

        // user2 stakes 250 CAP
        vm.prank(user2);
        staking.stake(250 * UNIT);

        // user3 submits order, incurring fees which are distributed to stakers
        uint256 feeInETH = _submitAndExecuteOrder(user3, 10 ether);
        uint256 feeInUSDC = _submitAndExecuteOrderAssetUSDC(user3, 5000 * USDC_DECIMALS);

        // user3 stakes after orders are executed
        vm.prank(user3);
        staking.stake(500 * UNIT);

        // asset array
        address[] memory assets = new address[](2);
        assets[0] = address(0);
        assets[1] = address(usdc);

        // user and user2 should receive staking rewards, user3 should receive nothing

        // user
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CollectedReward(user, address(0), (feeInETH * 3) / 4);
        staking.collectMultiple(assets);
        // rounding error of around 0.2% depending on total staked supply and pendingReward
        assertApproxEqRel(usdc.balanceOf(user) - usdcBalanceBefore, (feeInUSDC * 3) / 4, 0.003e18);

        // user 2
        usdcBalanceBefore = usdc.balanceOf(user2);
        vm.prank(user2);
        vm.expectEmit(true, true, true, true);
        emit CollectedReward(user2, address(0), feeInETH / 4);
        staking.collectMultiple(assets);
        // rounding error of around 0.2% depending on total staked supply and pendingReward
        assertApproxEqRel(usdc.balanceOf(user2) - usdcBalanceBefore, feeInUSDC / 4, 0.003e18);

        // user 3
        uint256 ethBalanceBefore = user3.balance;
        usdcBalanceBefore = usdc.balanceOf(user3);
        vm.prank(user3);
        staking.collectMultiple(assets);
        assertEq(ethBalanceBefore, user3.balance);
        assertEq(usdcBalanceBefore, usdc.balanceOf(user3));
    }

    function testNonWithdrawableFunds() public {
        // user stakes 1000 CAP
        vm.prank(user);
        staking.stake(1000 * UNIT);

        // user2 submits order, incurring fees which are distributed to user
        uint256 feeInETH = _submitAndExecuteOrder(user2, 10 ether);
        uint256 feeInUSDC = _submitAndExecuteOrderAssetUSDC(user2, 5000 * USDC_DECIMALS);

        // asset array
        address[] memory assets = new address[](2);
        assets[0] = address(0);
        assets[1] = address(usdc);

        // user claims staking rewards
        vm.prank(user);
        staking.collectMultiple(assets);

        // due to rounding errors a fraction of funds are left in the contract
        // leftover funds should be assigned to pendingReward, ready to be distributed later
        uint256 paidFeeInETH = user.balance - INITIAL_ETH_BALANCE;
        uint256 paidFeeInUSDC = usdc.balanceOf(user) - INITIAL_USDC_BALANCE;

        uint256 roundingErrorETH = feeInETH - paidFeeInETH;
        uint256 roundingErrorUSDC = feeInUSDC - paidFeeInUSDC;

        // assert correct pending reward
        assertEq(stakingStore.getPendingReward(address(0)), roundingErrorETH);
        assertEq(stakingStore.getPendingReward(address(usdc)), roundingErrorUSDC);
    }

    function testFuzzStakeAndUnstake(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_CAP_BALANCE);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CAPStaked(user, amount);
        staking.stake(amount);

        // check balances
        assertEq(stakingStore.getTotalSupply(), amount);
        assertEq(stakingStore.getBalance(user), amount);
        assertEq(cap.balanceOf(address(fundStore)), amount);
        assertEq(cap.balanceOf(user), INITIAL_CAP_BALANCE - amount);

        // Unstake
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CAPUnstaked(user, amount);
        staking.unstake(amount);

        // check balances
        assertEq(stakingStore.getTotalSupply(), 0);
        assertEq(stakingStore.getBalance(user), 0);
        assertEq(cap.balanceOf(address(fundStore)), 0);
        assertEq(cap.balanceOf(user), INITIAL_CAP_BALANCE);
    }

    // utils
    function _submitAndExecuteOrder(address _user, uint256 _size) internal returns (uint256) {
        btcLong.size = _size;
        uint256 fee = (_size * MARKET_FEE) / BPS_DIVIDER;

        // user submits BTC long order
        vm.prank(_user);
        orders.submitOrder{value: btcLong.margin + fee}(btcLong, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        // get order id
        orderIds[0] = orderStore.oid();

        // execute order
        processor.executeOrders{value: PYTH_FEE}(orderIds, priceFeedData);

        // return fee being distributed to cap stakers
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        uint256 netFee = fee - keeperFee;
        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;

        return feeToStaking;
    }

    function _submitAndExecuteOrderAssetUSDC(address _user, uint256 _size) internal returns (uint256) {
        btcLongAssetUSDC.size = _size;
        uint256 fee = (_size * MARKET_FEE) / BPS_DIVIDER;

        // user submits BTC long order
        vm.prank(_user);
        orders.submitOrder{value: btcLongAssetUSDC.margin + fee}(btcLongAssetUSDC, 0, 0);

        // fast forward 2 seconds due to market.minOrderAge = 1;
        skip(2);

        // priceFeedData and order array
        bytes[] memory priceFeedData = new bytes[](1);
        priceFeedData[0] = priceFeedDataBTC;
        uint256[] memory orderIds = new uint256[](1);
        // get order id
        orderIds[0] = orderStore.oid();

        // execute order
        processor.executeOrders{value: PYTH_FEE}(orderIds, priceFeedData);

        // return fee being distributed to cap stakers
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        uint256 netFee = fee - keeperFee;
        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;

        return feeToStaking;
    }

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
