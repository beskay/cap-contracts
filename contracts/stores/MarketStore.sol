// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../utils/Roles.sol';

contract MarketStore is Roles {
    struct Market {
        string name; // Bitcoin / U.S. Dollar
        string category; // crypto, fx, commodities, indices
        address chainlinkFeed;
        uint256 maxLeverage; // No decimals
        uint256 maxDeviation; // In bps, from chainlink feed
        uint256 fee; // In bps. 10 = 0.1%
        uint256 liqThreshold; // In bps
        uint256 fundingFactor; // Yearly funding rate if OI is completely skewed to one side. In bps.
        uint256 minOrderAge; // Min order age before is can be executed. In seconds
        uint256 pythMaxAge; // Max Pyth submitted price age, in seconds
        bytes32 pythFeed;
        bool allowChainlinkExecution; // Allow anyone to execute orders with chainlink
        bool isReduceOnly; // accepts only reduce only orders
    }

    uint256 public constant MAX_FEE = 1000; // 10%
    uint256 public constant MAX_DEVIATION = 1000; // 10%
    uint256 public constant MAX_LIQTHRESHOLD = 10000; // 100%
    uint256 public constant MAX_MIN_ORDER_AGE = 30;
    uint256 public constant MIN_PYTH_MAX_AGE = 3;

    string[] public marketList; // "ETH-USD", "BTC-USD", etc

    mapping(string => Market) private markets;

    bool public isGlobalReduceOnly;

    constructor(RoleStore rs) Roles(rs) {}

    // Setters

    function setIsGlobalReduceOnly(bool b) external onlyGov {
        isGlobalReduceOnly = b;
    }

    function set(string calldata market, Market memory marketInfo) external onlyGov {
        require(marketInfo.fee <= MAX_FEE, '!max-fee');
        require(marketInfo.maxLeverage >= 1, '!max-leverage');
        require(marketInfo.maxDeviation <= MAX_DEVIATION, '!max-deviation');
        require(marketInfo.liqThreshold <= MAX_LIQTHRESHOLD, '!max-liqthreshold');
        require(marketInfo.minOrderAge <= MAX_MIN_ORDER_AGE, '!max-minorderage');
        require(marketInfo.pythMaxAge >= MIN_PYTH_MAX_AGE, '!min-pythmaxage');

        markets[market] = marketInfo;
        for (uint256 i = 0; i < marketList.length; i++) {
            if (keccak256(abi.encodePacked(marketList[i])) == keccak256(abi.encodePacked(market))) return;
        }
        marketList.push(market);
    }

    // Getters

    function get(string calldata market) external view returns (Market memory) {
        return markets[market];
    }

    function getMany(string[] calldata _markets) external view returns (Market[] memory _marketInfos) {
        uint256 length = _markets.length;
        _marketInfos = new Market[](length);
        for (uint256 i = 0; i < length; i++) {
            _marketInfos[i] = markets[_markets[i]];
        }
        return _marketInfos;
    }

    function getMarketByIndex(uint256 index) external view returns (string memory) {
        return marketList[index];
    }

    function getMarketList() external view returns (string[] memory) {
        return marketList;
    }

    function getMarketCount() external view returns (uint256) {
        return marketList.length;
    }
}
