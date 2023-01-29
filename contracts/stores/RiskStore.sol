// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './DataStore.sol';
import './PoolStore.sol';
import './PositionStore.sol';

import '../utils/Roles.sol';

contract RiskStore is Roles {
    uint256 public constant BPS_DIVIDER = 10000;
    uint256 public constant MAX_POOL_PROFIT_LIMIT = 1000; // 10%

    mapping(string => mapping(address => uint256)) private maxOI; // market => asset => amount

    // Pool Risk Measures
    uint256 public poolHourlyDecay = 416; // bps = 4.16% hourly, disappears after 24 hours
    mapping(address => int256) private poolProfitTracker; // asset => amount (amortized)
    mapping(address => uint256) private poolProfitLimit; // asset => bps
    mapping(address => uint256) private poolLastChecked; // asset => timestamp

    DataStore public DS;

    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    // setters
    function setMaxOI(string calldata market, address asset, uint256 amount) external onlyGov {
        maxOI[market][asset] = amount;
    }

    function setPoolHourlyDecay(uint256 bps) external onlyGov {
        poolHourlyDecay = bps;
    }

    function setPoolProfitLimit(address asset, uint256 bps) external onlyGov {
        require(bps <= MAX_POOL_PROFIT_LIMIT, '!profit-limit');
        poolProfitLimit[asset] = bps;
    }

    // Checkers

    function checkMaxOI(address asset, string calldata market, uint256 size) external view {
        uint256 OI = PositionStore(DS.getAddress('PositionStore')).getOI(asset, market);
        uint256 _maxOI = maxOI[market][asset];
        if (_maxOI > 0 && OI + size > _maxOI) revert('!max-oi');
    }

    function checkPoolDrawdown(address asset, int256 pnl) external onlyContract {
        // pnl > 0 means trader win

        uint256 poolAvailable = PoolStore(DS.getAddress('PoolStore')).getAvailable(asset);
        int256 profitTracker = getPoolProfitTracker(asset) + pnl;

        poolProfitTracker[asset] = profitTracker;
        poolLastChecked[asset] = block.timestamp;

        uint256 profitLimit = poolProfitLimit[asset];

        if (profitLimit == 0 || profitTracker <= 0) return;

        require(uint256(profitTracker) < (profitLimit * poolAvailable) / BPS_DIVIDER, '!pool-risk');
    }

    // getters

    function getMaxOI(string calldata market, address asset) external view returns (uint256) {
        return maxOI[market][asset];
    }

    function getPoolProfitTracker(address asset) public view returns (int256) {
        int256 profitTracker = poolProfitTracker[asset];
        uint256 lastCheckedHourId = poolLastChecked[asset] / (1 hours);
        uint256 currentHourId = block.timestamp / (1 hours);
        if (currentHourId > lastCheckedHourId) {
            uint256 hoursPassed = currentHourId - lastCheckedHourId;
            if (hoursPassed >= BPS_DIVIDER / poolHourlyDecay) {
                profitTracker = 0;
            } else {
                for (uint256 i = 0; i < hoursPassed; i++) {
                    profitTracker *= (int256(BPS_DIVIDER) - int256(poolHourlyDecay)) / int256(BPS_DIVIDER);
                }
            }
        }
        return profitTracker;
    }

    function getPoolProfitLimit(address asset) external view returns (uint256) {
        return poolProfitLimit[asset];
    }
}
