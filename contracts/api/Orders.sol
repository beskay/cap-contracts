// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import 'hardhat/console.sol';

import '@openzeppelin/contracts/utils/Address.sol';

import '../stores/AssetStore.sol';
import '../stores/DataStore.sol';
import '../stores/FundStore.sol';
import '../stores/OrderStore.sol';
import '../stores/MarketStore.sol';
import '../stores/RiskStore.sol';

import '../utils/Chainlink.sol';
import '../utils/Roles.sol';

/*
Order of function / event params: id, user, asset, market
*/

contract Orders is Roles {
    using Address for address payable;

    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant BPS_DIVIDER = 10000;

    DataStore public DS;

    AssetStore public assetStore;
    FundStore public fundStore;
    MarketStore public marketStore;
    OrderStore public orderStore;
    RiskStore public riskStore;

    Chainlink public chainlink;

    event OrderCreated(
        uint32 indexed orderId,
        address indexed user,
        address indexed asset,
        string market,
        bool isLong,
        uint256 margin,
        uint256 size,
        uint256 price,
        uint256 fee,
        uint8 orderType,
        bool isReduceOnly,
        uint32 expiry,
        uint32 cancelOrderId
    );

    event OrderCancelled(uint256 indexed orderId, address indexed user, string reason);

    modifier ifNotPaused() {
        require(!orderStore.areNewOrdersPaused(), '!paused');
        _;
    }

    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    function link() external onlyGov {
        assetStore = AssetStore(DS.getAddress('AssetStore'));
        fundStore = FundStore(payable(DS.getAddress('FundStore')));
        marketStore = MarketStore(DS.getAddress('MarketStore'));
        orderStore = OrderStore(DS.getAddress('OrderStore'));
        riskStore = RiskStore(DS.getAddress('RiskStore'));
        chainlink = Chainlink(DS.getAddress('Chainlink'));
    }

    function submitOrder(
        OrderStore.Order memory params,
        uint256 tpPrice,
        uint256 slPrice
    ) external payable ifNotPaused {
        // value consumed
        uint256 vc1;
        uint256 vc2;
        uint256 vc3;

        if (tpPrice > 0 || slPrice > 0) {
            params.isReduceOnly = false;
        }

        (, vc1) = _submitOrder(params);

        // tp/sl price checks
        if (tpPrice > 0 || slPrice > 0) {
            if (params.price > 0) {
                if (tpPrice > 0) {
                    require(
                        (params.isLong && tpPrice > params.price) || (!params.isLong && tpPrice < params.price),
                        '!tp-invalid'
                    );
                }
                if (slPrice > 0) {
                    require(
                        (params.isLong && slPrice < params.price) || (!params.isLong && slPrice > params.price),
                        '!sl-invalid'
                    );
                }
            }

            if (tpPrice > 0 && slPrice > 0) {
                require((params.isLong && tpPrice > slPrice) || (!params.isLong && tpPrice < slPrice), '!tpsl-invalid');
            }

            // submit TP/SL orders
            uint32 tpOrderId;
            uint32 slOrderId;

            params.isLong = !params.isLong;

            if (tpPrice > 0) {
                params.price = tpPrice;
                params.orderType = 1;
                params.isReduceOnly = true;
                (tpOrderId, vc2) = _submitOrder(params);
            }
            if (slPrice > 0) {
                params.price = slPrice;
                params.orderType = 2;
                params.isReduceOnly = true;
                (slOrderId, vc3) = _submitOrder(params);
            }

            if (tpOrderId > 0 && slOrderId > 0) {
                // Update orders to cancel each other
                orderStore.updateCancelOrderId(tpOrderId, slOrderId);
                orderStore.updateCancelOrderId(slOrderId, tpOrderId);
            }
        }

        // Refund msg.value excess
        if (params.asset == address(0)) {
            uint256 diff = msg.value - vc1 - vc2 - vc3;
            if (diff > 0) {
                payable(msg.sender).sendValue(diff);
            }
        }
    }

    function _submitOrder(OrderStore.Order memory params) internal returns (uint32, uint256) {
        // console.log(1);

        // Validations
        {
            require(params.orderType == 0 || params.orderType == 1 || params.orderType == 2, '!order-type');

            if (params.orderType != 0) {
                require(params.price > 0, '!price');
            }

            // console.log(2);

            AssetStore.Asset memory asset = assetStore.get(params.asset);
            require(asset.minSize > 0, '!asset-exists');
            require(params.size >= asset.minSize, '!min-size');

            // console.log(3);

            MarketStore.Market memory market = marketStore.get(params.market);
            require(market.maxLeverage > 0, '!market-exists');

            // console.log(5);

            if (params.expiry > 0) {
                require(params.expiry >= block.timestamp, '!expiry-value');
                uint256 ttl = params.expiry - block.timestamp;
                require(
                    (params.orderType == 0 && ttl <= orderStore.maxMarketOrderTTL()) ||
                        ttl <= orderStore.maxTriggerOrderTTL(),
                    '!max-expiry'
                );
            }

            // console.log(6);

            if (params.cancelOrderId > 0) {
                require(orderStore.isUserOrder(params.cancelOrderId, msg.sender), '!user-oco');
            }

            if (!params.isReduceOnly) {
                require(!market.isReduceOnly, '!market-reduce-only');
                require(params.margin > 0, '!margin');

                uint256 leverage = (UNIT * params.size) / params.margin;
                require(leverage >= UNIT, '!min-leverage');
                require(leverage <= market.maxLeverage * UNIT, '!max-leverage');
            }
        }
        // console.log(7);

        // Set order params
        {
            params.user = msg.sender;
            params.timestamp = uint32(block.timestamp);

            MarketStore.Market memory market = marketStore.get(params.market);
            uint256 fee = (params.size * market.fee) / BPS_DIVIDER;
            params.fee = fee;
        }

        if (params.isReduceOnly) {
            // Existing position is checked on execution so TP/SL can be submitted as reduce-only alongside a non-executed order
            // In this case, valueConsumed is zero as margin is zero and fee is taken from the order's margin
            params.margin = 0;
        } else {
            // Check against max OI if it's not reduce-only. this is not completely fail safe as user can place many consecutive market orders of smaller size and get past the max OI limit here, because OI is not updated until keeper picks up the order. That is why maxOI is checked on processing as well, which is fail safe. This check is more of preemptive for user to not submit an order
            riskStore.checkMaxOI(params.asset, params.market, params.size);

            // Transfer fee and margin to store
            uint256 valueConsumed = params.margin + params.fee;

            if (params.asset == address(0)) {
                fundStore.transferIn{value: valueConsumed}(params.asset, params.user, valueConsumed);
            } else {
                fundStore.transferIn(params.asset, params.user, valueConsumed);
            }
        }

        // console.log(8);

        // Add order to store
        params.orderId = orderStore.add(params);

        // console.log(9);

        emit OrderCreated(
            params.orderId,
            params.user,
            params.asset,
            params.market,
            params.isLong,
            params.margin,
            params.size,
            params.price,
            params.fee,
            params.orderType,
            params.isReduceOnly,
            params.expiry,
            params.cancelOrderId
        );

        return (params.orderId, params.isReduceOnly ? 0 : params.margin + params.fee);
    }

    function cancelOrder(uint32 orderId) external ifNotPaused {
        OrderStore.Order memory order = orderStore.get(orderId);
        require(order.size > 0, '!order');
        require(order.user == msg.sender, '!user');
        _cancelOrder(orderId, 'by-user');
    }

    function cancelOrders(uint32[] calldata orderIds) external ifNotPaused {
        for (uint256 i = 0; i < orderIds.length; i++) {
            OrderStore.Order memory order = orderStore.get(orderIds[i]);
            if (order.size > 0 && order.user == msg.sender) {
                _cancelOrder(orderIds[i], 'by-user');
            }
        }
    }

    function cancelOrder(uint32 orderId, string calldata reason) external onlyContract {
        _cancelOrder(orderId, reason);
    }

    function cancelOrders(uint32[] calldata orderIds, string[] calldata reasons) external onlyContract {
        for (uint256 i = 0; i < orderIds.length; i++) {
            _cancelOrder(orderIds[i], reasons[i]);
        }
    }

    function _cancelOrder(uint32 orderId, string memory reason) internal {
        OrderStore.Order memory order = orderStore.get(orderId);
        if (order.size == 0) return;

        orderStore.remove(orderId);

        fundStore.transferOut(order.asset, order.user, order.margin + order.fee);

        emit OrderCancelled(orderId, order.user, reason);
    }
}
