// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../stores/DataStore.sol";
import "../stores/FundingStore.sol";
import "../stores/MarketStore.sol";
import "../stores/PositionStore.sol";

import "../utils/Roles.sol";

contract Funding is Roles {

	event FundingUpdated(
        address indexed asset,
        string market,
        int256 fundingTracker,
	    int256 fundingIncrement
    );

    uint256 public constant UNIT = 10**18;

    DataStore public DS;
	FundingStore public fundingStore;
	MarketStore public marketStore;
	PositionStore public positionStore;

	constructor(RoleStore rs, DataStore ds) Roles(rs) {
		DS = ds;
	}

	function link() external onlyGov {
		fundingStore = FundingStore(DS.getAddress('FundingStore'));
		marketStore = MarketStore(DS.getAddress('MarketStore'));
		positionStore = PositionStore(DS.getAddress('PositionStore'));
	}

	function updateFundingTracker(address asset, string memory market) external onlyContract {
		
		uint256 lastUpdated = fundingStore.getLastUpdated(asset, market);
		uint256 _now = block.timestamp;
		
		if (lastUpdated == 0) {
	    	fundingStore.setLastUpdated(asset, market, _now);
	    	return;
	    }

		if (lastUpdated + fundingStore.fundingInterval() > _now) return;
	    
	    int256 fundingIncrement = getAccruedFunding(asset, market, 0); // in UNIT * bps

	    if (fundingIncrement == 0) return;
    	
    	fundingStore.updateFundingTracker(asset, market, fundingIncrement);
    	fundingStore.setLastUpdated(asset, market, _now);
	    
	    emit FundingUpdated(
	    	asset,
	    	market,
	    	fundingStore.getFundingTracker(asset, market),
	    	fundingIncrement
	    );

	}

	function getAccruedFunding(address asset, string memory market, uint256 intervals) public view returns (int256) {
		
		if (intervals == 0) {
			intervals = (block.timestamp - fundingStore.getLastUpdated(asset, market)) / fundingStore.fundingInterval();
		}
		
		if (intervals == 0) return 0;
	    
	    uint256 OILong = positionStore.getOILong(asset, market);
	    uint256 OIShort = positionStore.getOIShort(asset, market);
	    
	    if (OIShort == 0 && OILong == 0) return 0;

	    uint256 OIDiff = OIShort > OILong ? OIShort - OILong : OILong - OIShort;

	    MarketStore.Market memory marketInfo = marketStore.get(market);

	    uint256 yearlyFundingFactor = marketInfo.fundingFactor;

	    uint256 accruedFunding = UNIT * yearlyFundingFactor * OIDiff * intervals / (24 * 365 * (OILong + OIShort)); // in UNIT * bps

	    if (OILong > OIShort) {
	    	// Longs pay shorts. Increase funding tracker.
	    	return int256(accruedFunding);
	    } else {
	    	// Shorts pay longs. Decrease funding tracker.
	    	return -1 * int256(accruedFunding);
	    }

	}

}