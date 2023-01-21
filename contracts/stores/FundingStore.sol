// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../utils/Roles.sol';

contract FundingStore is Roles {
    constructor(RoleStore rs) Roles(rs) {}

    uint256 public fundingInterval = 1 hours; // In seconds.
    mapping(address => mapping(string => int256)) private fundingTrackers; // asset => market => funding tracker (long) (short is opposite)
    mapping(address => mapping(string => uint256)) private lastUpdated; // asset => market => last time fundingTracker was updated. In seconds.

    // Setters

    function setFundingInterval(uint256 amount) external onlyGov {
        fundingInterval = amount;
    }

    function setLastUpdated(address asset, string memory market, uint256 timestamp) external onlyContract {
        lastUpdated[asset][market] = timestamp;
    }

    function updateFundingTracker(address asset, string memory market, int256 fundingIncrement) external onlyContract {
        fundingTrackers[asset][market] += fundingIncrement;
    }

    // Getters

    function getLastUpdated(address asset, string memory market) external view returns (uint256) {
        return lastUpdated[asset][market];
    }

    function getFundingTracker(address asset, string memory market) external view returns (int256) {
        return fundingTrackers[asset][market];
    }

    function getFundingTrackers(
        address[] calldata assets,
        string[] calldata markets
    ) external view returns (int256[] memory fts) {
        uint256 length = assets.length;
        fts = new int256[](length);
        for (uint256 i = 0; i < length; i++) {
            fts[i] = fundingTrackers[assets[i]][markets[i]];
        }
        return fts;
    }
}
