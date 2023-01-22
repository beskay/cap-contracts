// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import 'hardhat/console.sol';

import '../stores/AssetStore.sol';
import '../stores/DataStore.sol';
import '../stores/FundStore.sol';
import '../stores/PoolStore.sol';

import '../utils/Roles.sol';

contract Pool is Roles {
    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant BPS_DIVIDER = 10000;

    DataStore public DS;

    AssetStore public assetStore;
    FundStore public fundStore;
    PoolStore public poolStore;

    event PoolDeposit(
        address indexed user,
        address indexed asset,
        uint256 amount,
        uint256 clpAmount,
        uint256 poolBalance
    );

    event PoolWithdrawal(
        address indexed user,
        address indexed asset,
        uint256 amount,
        uint256 feeAmount,
        uint256 clpAmount,
        uint256 poolBalance
    );

    event PoolPayIn(
        address indexed user,
        address indexed asset,
        string market,
        uint256 amount,
        uint256 bufferToPoolAmount,
        uint256 poolBalance,
        uint256 bufferBalance
    );

    event PoolPayOut(
        address indexed user,
        address indexed asset,
        string market,
        uint256 amount,
        uint256 poolBalance,
        uint256 bufferBalance
    );

    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    function link() external onlyGov {
        assetStore = AssetStore(DS.getAddress('AssetStore'));
        fundStore = FundStore(payable(DS.getAddress('FundStore')));
        poolStore = PoolStore(DS.getAddress('PoolStore'));
    }

    // credit trader loss to buffer. also pay pool from buffer amount based on time and payout rate
    function creditTraderLoss(address user, address asset, string memory market, uint256 amount) external onlyContract {
        poolStore.incrementBufferBalance(asset, amount);

        uint256 lastPaid = poolStore.getLastPaid(asset);
        uint256 _now = block.timestamp;
        uint256 amountToSendPool;

        if (lastPaid == 0) {
            poolStore.setLastPaid(asset, _now);
        } else {
            uint256 bufferBalance = poolStore.getBufferBalance(asset);
            uint256 bufferPayoutPeriod = poolStore.bufferPayoutPeriod();

            amountToSendPool = (bufferBalance * (block.timestamp - lastPaid)) / bufferPayoutPeriod;

            if (amountToSendPool > bufferBalance) amountToSendPool = bufferBalance;

            poolStore.incrementBalance(asset, amountToSendPool);
            poolStore.decrementBufferBalance(asset, amountToSendPool);
            poolStore.setLastPaid(asset, _now);
        }

        emit PoolPayIn(
            user,
            asset,
            market,
            amount,
            amountToSendPool,
            poolStore.getBalance(asset),
            poolStore.getBufferBalance(asset)
        );
    }

    // pay out trader win, from buffer first then pool if buffer is depleted
    function debitTraderProfit(
        address user,
        address asset,
        string calldata market,
        uint256 amount
    ) external onlyContract {
        if (amount == 0) return;

        uint256 bufferBalance = poolStore.getBufferBalance(asset);

        poolStore.decrementBufferBalance(asset, amount);

        if (amount > bufferBalance) {
            uint256 diffToPayFromPool = amount - bufferBalance;
            uint256 poolBalance = poolStore.getBalance(asset);
            require(diffToPayFromPool < poolBalance, '!pool-balance');
            poolStore.decrementBalance(asset, diffToPayFromPool);
        }

        fundStore.transferOut(asset, user, amount);

        emit PoolPayOut(user, asset, market, amount, poolStore.getBalance(asset), poolStore.getBufferBalance(asset));
    }

    function deposit(address asset, uint256 amount) public payable {
        require(amount > 0, '!amount');
        require(assetStore.isSupported(asset), '!asset');

        uint256 balance = poolStore.getBalance(asset);
        uint256 clpSupply = poolStore.getClpSupply(asset);
        uint256 clpAmount = balance == 0 || clpSupply == 0 ? amount : (amount * clpSupply) / balance;

        poolStore.incrementUserClpBalance(asset, msg.sender, clpAmount);
        poolStore.incrementBalance(asset, amount);

        // transfer funds
        if (asset == address(0)) {
            amount = msg.value;
            fundStore.transferIn{value: amount}(asset, msg.sender, amount);
        } else {
            fundStore.transferIn(asset, msg.sender, amount);
        }

        emit PoolDeposit(msg.sender, asset, amount, clpAmount, poolStore.getBalance(asset));
    }

    function withdraw(address asset, uint256 amount) public {
        require(amount > 0, '!amount');
        require(assetStore.isSupported(asset), '!asset');

        uint256 balance = poolStore.getBalance(asset);
        uint256 clpSupply = poolStore.getClpSupply(asset);
        require(balance > 0 && clpSupply > 0, '!empty');

        uint256 userBalance = poolStore.getUserBalance(asset, msg.sender);
        if (amount > userBalance) amount = userBalance;

        uint256 feeAmount = (amount * poolStore.getWithdrawalFee(asset)) / BPS_DIVIDER;
        uint256 amountMinusFee = amount - feeAmount;

        // CLP amount
        uint256 clpAmount = (amountMinusFee * clpSupply) / balance;

        poolStore.decrementUserClpBalance(asset, msg.sender, clpAmount);
        poolStore.decrementBalance(asset, amountMinusFee);

        // Transfer Funds
        fundStore.transferOut(asset, msg.sender, amountMinusFee);

        emit PoolWithdrawal(msg.sender, asset, amount, feeAmount, clpAmount, poolStore.getBalance(asset));
    }
}
