// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import './utils/Setup.t.sol';

contract RoleTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function testAddRole() public {
        roleStore.grantRole(user, TEST_ROLE);

        // at this point there should be two roles: TEST_ROLE and CONTRACT_ROLE
        assertEq(roleStore.getRoleCount(), 2);

        // user should have TEST_ROLE
        assertTrue(roleStore.hasRole(user, TEST_ROLE));
    }

    function testRevokeRole() public {
        testAddRole();

        roleStore.revokeRole(user, TEST_ROLE);

        assertFalse(roleStore.hasRole(user, TEST_ROLE));
        // TEST_ROLE should be removed
        assertEq(roleStore.getRoleCount(), 1);
    }

    function testRevertContractRole() public {
        // fund fundstore
        deal(address(fundStore), 1 ether);

        // should revert if non contract address calls onlyContract function
        vm.prank(user);
        vm.expectRevert('!contract-role');
        fundStore.transferOut(address(0), user, 1 ether);
    }
}
