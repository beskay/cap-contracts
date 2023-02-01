// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './Constants.sol';

import 'contracts/stores/AssetStore.sol';
import 'contracts/stores/DataStore.sol';
import 'contracts/stores/FundingStore.sol';
import 'contracts/stores/FundStore.sol';
import 'contracts/stores/MarketStore.sol';
import 'contracts/stores/OrderStore.sol';
import 'contracts/stores/PoolStore.sol';
import 'contracts/stores/PositionStore.sol';
import 'contracts/stores/RiskStore.sol';
import 'contracts/stores/RoleStore.sol';
import 'contracts/stores/StakingStore.sol';

import 'contracts/utils/Governable.sol';
import 'contracts/utils/Roles.sol';

import 'contracts/api/Funding.sol';
import 'contracts/api/Orders.sol';
import 'contracts/api/Pool.sol';
import 'contracts/api/Positions.sol';
import 'contracts/api/Processor.sol';
import 'contracts/api/Staking.sol';

import '@pythnetwork/pyth-sdk-solidity/MockPyth.sol';
import 'contracts/mocks/MockChainlink.sol';
import 'contracts/mocks/MockToken.sol';

contract Setup is Constants {
    AssetStore public assetStore;
    DataStore public dataStore;
    FundingStore public fundingStore;
    FundStore public fundStore;
    MarketStore public marketStore;
    OrderStore public orderStore;
    PoolStore public poolStore;
    PositionStore public positionStore;
    RiskStore public riskStore;
    RoleStore public roleStore;
    StakingStore public stakingStore;

    Governable public governable;
    Roles public roles;

    Funding public funding;
    Orders public orders;
    Pool public pool;
    Positions public positions;
    Processor public processor;
    Staking public staking;

    MockPyth public pyth;
    MockChainlink public chainlink;

    MockToken public cap;
    MockToken public usdc;

    // Pyth price data
    bytes priceFeedDataETH;
    bytes priceFeedDataBTC;

    // Test orders
    OrderStore.Order public ethLong =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0),
            market: 'ETH-USD',
            margin: 0.5 ether,
            size: 5 ether,
            price: 0, // market order
            fee: 0,
            isLong: true, // long
            orderType: 0,
            isReduceOnly: false,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });
    OrderStore.Order public ethShort =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0),
            market: 'ETH-USD',
            margin: 0.5 ether,
            size: 5 ether,
            price: 0, // market order
            fee: 0,
            isLong: false, // short
            orderType: 0,
            isReduceOnly: false,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });
    OrderStore.Order public ethLimitLong =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0),
            market: 'ETH-USD',
            margin: 1 ether,
            size: 5 ether,
            price: 950 * UNIT, // limit order
            fee: 0,
            isLong: true, // long
            orderType: 1,
            isReduceOnly: false,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });
    OrderStore.Order public ethLimitShort =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0),
            market: 'ETH-USD',
            margin: 1 ether,
            size: 5 ether,
            price: 1050 * UNIT, // limit order
            fee: 0,
            isLong: false, // short
            orderType: 1,
            isReduceOnly: false,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });
    OrderStore.Order public ethStopLong =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0),
            market: 'ETH-USD',
            margin: 2 ether,
            size: 5 ether,
            price: 1100 * UNIT, // stop order
            fee: 0,
            isLong: true, // long
            orderType: 2,
            isReduceOnly: false,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });
    OrderStore.Order public ethStopShort =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0),
            market: 'ETH-USD',
            margin: 3 ether,
            size: 10 ether,
            price: 900 * UNIT, // stop order
            fee: 0,
            isLong: false, // short
            orderType: 2,
            isReduceOnly: false,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });
    OrderStore.Order public btcLong =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0),
            market: 'BTC-USD', // new market
            margin: 1 ether,
            size: 5 ether,
            price: 0, // market order
            fee: 0,
            isLong: true, // long
            orderType: 0,
            isReduceOnly: false,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });
    OrderStore.Order public btcLongAssetUSDC =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0), // will be set after contract deployment
            market: 'BTC-USD',
            margin: 1000 * USDC_DECIMALS,
            size: 5000 * USDC_DECIMALS,
            price: 0, // market order
            fee: 0,
            isLong: true, // long
            orderType: 0,
            isReduceOnly: false,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });
    OrderStore.Order public reduceOnly =
        OrderStore.Order({
            orderId: 0,
            user: address(0),
            asset: address(0),
            market: 'BTC-USD',
            margin: 1 ether, // should be set to zero
            size: 5 ether,
            price: 0, // market order
            fee: 0,
            isLong: false, // short
            orderType: 0,
            isReduceOnly: true,
            timestamp: 0,
            expiry: 0,
            cancelOrderId: 0
        });

    function setUp() public virtual {
        // fast forward to year 2023
        skip(1672531200);

        // Mock Tokens - CAP, USDC
        cap = new MockToken('CAP', 'CAP', 18);
        console.log('Cap token deployed to', address(cap));
        usdc = new MockToken('USDC', 'USDC', 6);
        console.log('USDC token deployed to', address(usdc));

        // Mock Pyth: _validTimePeriod = 10 seconds, _singleUpdateFeeInWei = 0
        pyth = new MockPyth(10, 0);
        console.log('MockPyth deployed to', address(pyth));

        // Mock chainlink
        chainlink = new MockChainlink();
        console.log('MockChainlink deployed to', address(chainlink));

        // Governable
        governable = new Governable();
        console.log('Governable deployed to', address(governable));

        // RoleStore
        roleStore = new RoleStore();
        console.log('RoleStore deployed to', address(roleStore));

        console.log('--------');

        // DataStore
        dataStore = new DataStore();
        console.log('DataStore deployed to', address(dataStore));

        console.log('--------');

        // AssetStore
        assetStore = new AssetStore(roleStore);
        console.log('AssetStore deployed to', address(assetStore));

        // FundingStore
        fundingStore = new FundingStore(roleStore);
        console.log('FundingStore deployed to', address(fundingStore));

        // FundStore
        fundStore = new FundStore(roleStore);
        console.log('FundStore deployed to', address(fundStore));

        // MarketStore
        marketStore = new MarketStore(roleStore);
        console.log('MarketStore deployed to', address(marketStore));

        // OrderStore
        orderStore = new OrderStore(roleStore);
        console.log('OrderStore deployed to', address(orderStore));

        // PoolStore
        poolStore = new PoolStore(roleStore);
        console.log('PoolStore deployed to', address(poolStore));

        // PositionStore
        positionStore = new PositionStore(roleStore);
        console.log('PositionStore deployed to', address(positionStore));

        // RiskStore
        riskStore = new RiskStore(roleStore, dataStore);
        console.log('RiskStore deployed to', address(riskStore));

        // StakingStore
        stakingStore = new StakingStore(roleStore);
        console.log('StakingStore deployed to', address(stakingStore));

        // Funding
        funding = new Funding(roleStore, dataStore);
        console.log('Funding deployed to', address(funding));

        // Orders
        orders = new Orders(roleStore, dataStore);
        console.log('Orders deployed to', address(orders));

        // Pool
        pool = new Pool(roleStore, dataStore);
        console.log('Pool deployed to', address(pool));

        // Positions
        positions = new Positions(roleStore, dataStore);
        console.log('Positions deployed to', address(positions));

        // Processor
        processor = new Processor(roleStore, dataStore);
        console.log('Processor deployed to', address(processor));

        // Staking
        staking = new Staking(roleStore, dataStore);
        console.log('Staking deployed to', address(staking));

        // CONTRACT SETUP //

        // Data

        // Contract addresses
        dataStore.setAddress('AssetStore', address(assetStore), true);
        dataStore.setAddress('FundingStore', address(fundingStore), true);
        dataStore.setAddress('FundStore', address(fundStore), true);
        dataStore.setAddress('MarketStore', address(marketStore), true);
        dataStore.setAddress('OrderStore', address(orderStore), true);
        dataStore.setAddress('PoolStore', address(poolStore), true);
        dataStore.setAddress('PositionStore', address(positionStore), true);
        dataStore.setAddress('RiskStore', address(riskStore), true);
        dataStore.setAddress('StakingStore', address(stakingStore), true);
        dataStore.setAddress('Funding', address(funding), true);
        dataStore.setAddress('Orders', address(orders), true);
        dataStore.setAddress('Pool', address(pool), true);
        dataStore.setAddress('Positions', address(positions), true);
        dataStore.setAddress('Processor', address(processor), true);
        dataStore.setAddress('Staking', address(staking), true);
        dataStore.setAddress('CAP', address(cap), true);
        dataStore.setAddress('USDC', address(usdc), true);
        dataStore.setAddress('Chainlink', address(chainlink), true);
        dataStore.setAddress('Pyth', address(pyth), true);
        dataStore.setAddress('treasury', msg.sender, true);
        console.log('Data addresses configured.');

        // Link
        funding.link();
        orders.link();
        pool.link();
        positions.link();
        processor.link();
        staking.link();
        console.log('Contracts linked.');

        // Grant roles
        roleStore.grantRole(address(funding), CONTRACT_ROLE);
        roleStore.grantRole(address(orders), CONTRACT_ROLE);
        roleStore.grantRole(address(pool), CONTRACT_ROLE);
        roleStore.grantRole(address(positions), CONTRACT_ROLE);
        roleStore.grantRole(address(processor), CONTRACT_ROLE);
        roleStore.grantRole(address(staking), CONTRACT_ROLE);
        console.log('Roles configured.');

        // Currencies
        assetStore.set(address(0), AssetStore.Asset(0.01 ether, address(0)));
        assetStore.set(address(usdc), AssetStore.Asset(10 * 10 ** 6, address(0)));
        console.log('Assets configured.');

        // Chainlink prices, 18 decimals
        chainlink.setMarketPrice(linkETH, ETH_PRICE * UNIT);
        chainlink.setMarketPrice(linkBTC, BTC_PRICE * UNIT);
        chainlink.setMarketPrice(linkUSDC, 1 * UNIT);

        // Pyth price feed data
        priceFeedDataETH = pyth.createPriceFeedUpdateData(
            pythETH, // price feed ID
            int64(uint64(ETH_PRICE * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(ETH_PRICE * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );
        priceFeedDataBTC = pyth.createPriceFeedUpdateData(
            pythBTC, // price feed ID
            int64(uint64(BTC_PRICE * 10 ** 8)), // price
            uint64(10 ** 8), // confidence interval (10^8 * 10^(expo) = 1)
            int32(-8), // exponent
            int64(uint64(BTC_PRICE * 10 ** 8)), // ema price
            uint64(10 ** 8), // confidence interval
            uint64(block.timestamp) // publishTime
        );

        console.log('Prices configured.');

        // Markets
        marketStore.set(
            'ETH-USD',
            MarketStore.Market({
                name: 'Ethereum / U.S. Dollar',
                category: 'crypto',
                maxLeverage: 50,
                maxDeviation: 500,
                chainlinkFeed: linkETH,
                fee: 10, // 0.1%
                liqThreshold: 10000,
                fundingFactor: 10000,
                minOrderAge: 1,
                pythMaxAge: 20,
                pythFeed: pythETH,
                allowChainlinkExecution: true,
                isReduceOnly: false
            })
        );
        marketStore.set(
            'BTC-USD',
            MarketStore.Market({
                name: 'Bitcoin / U.S. Dollar',
                category: 'crypto',
                maxLeverage: 50,
                maxDeviation: 500,
                fee: 10,
                chainlinkFeed: linkBTC,
                liqThreshold: 10000,
                fundingFactor: 10000,
                minOrderAge: 1,
                pythMaxAge: 20,
                pythFeed: pythBTC,
                allowChainlinkExecution: true,
                isReduceOnly: false
            })
        );

        console.log('Markets configured.');

        // Mint and approve some mock tokens

        usdc.mint(100_000 * USDC_DECIMALS);
        usdc.approve(address(fundStore), MAX_UINT256);
        cap.mint(1000 * UNIT);
        cap.approve(address(fundStore), MAX_UINT256);

        // To user
        vm.startPrank(user);
        usdc.mint(100_000 * USDC_DECIMALS);
        usdc.approve(address(fundStore), MAX_UINT256);
        cap.mint(1000 * UNIT);
        cap.approve(address(fundStore), MAX_UINT256);
        vm.stopPrank();

        // To user2
        vm.startPrank(user2);
        usdc.mint(100_000 * USDC_DECIMALS);
        usdc.approve(address(fundStore), MAX_UINT256);
        cap.mint(1000 * UNIT);
        cap.approve(address(fundStore), MAX_UINT256);
        vm.stopPrank();

        console.log('Minted mock tokens.');

        // Fund accounts
        vm.deal(msg.sender, 10 ether);
        vm.deal(user, 10 ether);
        vm.deal(user2, 10 ether);
        console.log('User accounts funded.');

        // set USDC address of orders
        btcLongAssetUSDC.asset = address(usdc);
    }
}
