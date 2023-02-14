// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

contract Constants is Test {
    // Roles
    bytes32 constant CONTRACT_ROLE = keccak256('CONTRACT');
    bytes32 constant TEST_ROLE = keccak256('TEST');

    // Constants
    uint256 public constant MAX_UINT256 = 2 ** 256 - 1;
    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant BPS_DIVIDER = 10000;
    uint256 public constant USDC_DECIMALS = 10 ** 6;
    uint256 public constant INITIAL_ETH_BALANCE = 10 ether;
    uint256 public constant INITIAL_USDC_BALANCE = 100_000 * USDC_DECIMALS;

    // Prices for test orders
    uint256 public constant ETH_PRICE = 1000;
    uint256 public constant BTC_PRICE = 10000;

    uint256 public constant ETH_SL_PRICE = 950;
    uint256 public constant BTC_SL_PRICE = 9500;

    uint256 public constant ETH_TP_PRICE = 1050;
    uint256 public constant BTC_TP_PRICE = 10500;

    // Chainlink price feeds
    address public linkUSDC = makeAddr('USDC');
    address public linkETH = makeAddr('ETH-USD');
    address public linkBTC = makeAddr('BTC-USD');

    // Pyth price feeds
    bytes32 constant pythETH = keccak256('ETH-USD');
    bytes32 constant pythBTC = keccak256('BTC-USD');

    // Test addresses
    address public treasury = makeAddr('Treasury');
    address public user = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
    address public user2 = address(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
}
