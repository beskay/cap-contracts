// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title MockChainlink
/// @notice Mock chainlink contract used for tests
contract MockChainlink {
    mapping(address => uint256) marketPrices;

    constructor() {}

    /// @dev sets market price of `feed`
    /// @param feed price feed address
    /// @param price 18 decimal price
    function setMarketPrice(address feed, uint256 price) external {
        marketPrices[feed] = price;
    }

    /// @dev returns price of specified feed
    /// @param feed price feed address
    function getPrice(address feed) external view returns (uint256) {
        return marketPrices[feed];
    }
}
