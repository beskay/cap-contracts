// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title ChainlinkBase
/// @notice Mock chainlink contract used for Base until Chainlink support is given
contract ChainlinkBase {
    constructor() {}

    /// @dev returns price of specified feed
    /// @param feed price feed address
    function getPrice(address feed) external pure returns (uint256) {
        return 0;
    }
}
