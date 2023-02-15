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

    function testFuzzStakeAndUnstake(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000 * UNIT);

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CAPStaked(user, amount);
        staking.stake(amount);

        // check balances
        assertEq(stakingStore.getTotalSupply(), amount);
        assertEq(stakingStore.getBalance(user), amount);
        assertEq(cap.balanceOf(address(fundStore)), amount);
        assertEq(cap.balanceOf(user), 1000 * UNIT - amount);

        // Unstake
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CAPUnstaked(user, amount);
        staking.unstake(amount);

        // check balances
        assertEq(stakingStore.getTotalSupply(), 0);
        assertEq(stakingStore.getBalance(user), 0);
        assertEq(cap.balanceOf(address(fundStore)), 0);
        assertEq(cap.balanceOf(user), 1000 * UNIT);
    }
}
