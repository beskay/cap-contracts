// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

/// @title Chainlink
/// @notice Consumes price data
contract ChainlinkPolygon {
    // -- Constants -- //
    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant RATE_STALE_PERIOD = 86400;

    // -- Errors -- //
    error StaleRate();

    /**
     * For a list of available sequencer proxy addresses, see:
     * https://docs.chain.link/docs/l2-sequencer-flag/#available-networks
     */

    // -- Constructor -- //
    constructor() {}

    // Returns the latest price
    function getPrice(address feed) public view returns (uint256) {
        if (feed == address(0)) return 0;

        AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);

        // prettier-ignore
        (
            /*uint80 roundID*/, 
            int price, 
            /*uint startedAt*/,
            uint256 updatedAt, 
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        if (updatedAt < block.timestamp - RATE_STALE_PERIOD) {
            revert StaleRate();
        }

        uint8 decimals = priceFeed.decimals();

        // Return 18 decimals standard
        return (uint256(price) * UNIT) / 10 ** decimals;
    }
}
