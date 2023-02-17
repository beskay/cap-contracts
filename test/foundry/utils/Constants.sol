// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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
    uint256 public constant INITIAL_CAP_BALANCE = 1000 * UNIT;

    uint256 public constant PYTH_FEE = 1000; // 1000 wei
    uint256 public constant MARKET_FEE = 10; // in bps

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
    address public user = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266); // first anvil test address
    address public user2 = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8); // second anvil test address
    address public user3 = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC); // third anvil test address
}
