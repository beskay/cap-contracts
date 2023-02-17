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
        uint256 orderSize = 10 ether;
        _submitAndExecuteOrder(user3, orderSize, btcLong, priceFeedDataBTC);

        // calculate staking fee
        uint256 fee = (orderSize * MARKET_FEE) / BPS_DIVIDER;
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        uint256 netFee = fee - keeperFee;
        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;

        // user3 stakes after orders are executed
        vm.prank(user3);
        staking.stake(500 * UNIT);

        // user and user2 should receive staking rewards, user3 should receive nothing
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CollectedReward(user, address(0), (feeToStaking * 3) / 4);
        staking.collectReward(address(0));

        vm.prank(user2);
        vm.expectEmit(true, true, true, true);
        emit CollectedReward(user2, address(0), feeToStaking / 4);
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
        uint256 orderSize = 5000 * USDC_DECIMALS;
        _submitAndExecuteOrder(user3, orderSize, btcLongAssetUSDC, priceFeedDataBTC);

        // calculate staking fee
        uint256 fee = (orderSize * MARKET_FEE) / BPS_DIVIDER;
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        uint256 netFee = fee - keeperFee;
        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;

        // user3 stakes after orders are executed
        vm.prank(user3);
        staking.stake(500 * UNIT);

        // user and user2 should receive staking rewards, user3 should receive nothing

        // user
        uint256 usdcBalanceBefore = usdc.balanceOf(user);
        vm.prank(user);
        staking.collectReward(address(usdc));
        // rounding error of around 0.2% depending on total staked supply and pendingReward
        assertApproxEqRel(usdc.balanceOf(user) - usdcBalanceBefore, (feeToStaking * 3) / 4, 0.003e18);

        // user2
        usdcBalanceBefore = usdc.balanceOf(user2);
        vm.prank(user2);
        staking.collectReward(address(usdc));
        // rounding error of around 0.2% depending on total staked supply and pendingReward
        assertApproxEqRel(usdc.balanceOf(user2) - usdcBalanceBefore, feeToStaking / 4, 0.003e18);

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

        // user3 submits orders, incurring fees which are distributed to stakers
        uint256 orderSizeETH = 10 ether;
        _submitAndExecuteOrder(user3, orderSizeETH, btcLong, priceFeedDataBTC);

        uint256 orderSizeUSDC = 5000 * USDC_DECIMALS;
        _submitAndExecuteOrder(user3, orderSizeUSDC, btcLongAssetUSDC, priceFeedDataBTC);

        // calculate staking fees
        uint256 fee = (orderSizeETH * MARKET_FEE) / BPS_DIVIDER;
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        uint256 netFee = fee - keeperFee;
        uint256 feeToStakinginETH = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;

        fee = (orderSizeUSDC * MARKET_FEE) / BPS_DIVIDER;
        keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        netFee = fee - keeperFee;
        uint256 feeToStakinginUSDC = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;

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
        emit CollectedReward(user, address(0), (feeToStakinginETH * 3) / 4);
        staking.collectMultiple(assets);
        // rounding error of around 0.2% depending on total staked supply and pendingReward
        assertApproxEqRel(usdc.balanceOf(user) - usdcBalanceBefore, (feeToStakinginUSDC * 3) / 4, 0.003e18);

        // user 2
        usdcBalanceBefore = usdc.balanceOf(user2);
        vm.prank(user2);
        vm.expectEmit(true, true, true, true);
        emit CollectedReward(user2, address(0), feeToStakinginETH / 4);
        staking.collectMultiple(assets);
        // rounding error of around 0.2% depending on total staked supply and pendingReward
        assertApproxEqRel(usdc.balanceOf(user2) - usdcBalanceBefore, feeToStakinginUSDC / 4, 0.003e18);

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

        // user3 submits orders, incurring fees which are distributed to stakers
        uint256 orderSizeETH = 10 ether;
        _submitAndExecuteOrder(user3, orderSizeETH, btcLong, priceFeedDataBTC);

        uint256 orderSizeUSDC = 5000 * USDC_DECIMALS;
        _submitAndExecuteOrder(user3, orderSizeUSDC, btcLongAssetUSDC, priceFeedDataBTC);

        // calculate staking fees
        uint256 fee = (orderSizeETH * MARKET_FEE) / BPS_DIVIDER;
        uint256 keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        uint256 netFee = fee - keeperFee;
        uint256 feeToStakinginETH = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;

        fee = (orderSizeUSDC * MARKET_FEE) / BPS_DIVIDER;
        keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        netFee = fee - keeperFee;
        uint256 feeToStakinginUSDC = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;

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

        uint256 roundingErrorETH = feeToStakinginETH - paidFeeInETH;
        uint256 roundingErrorUSDC = feeToStakinginUSDC - paidFeeInUSDC;

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

    // needed to receive Ether (e.g. keeper fee)
    receive() external payable {}
}
