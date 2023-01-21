const { time, loadFixture, takeSnapshot } = require('@nomicfoundation/hardhat-network-helpers');
// https://hardhat.org/hardhat-network-helpers/docs/reference

const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');
// https://hardhat.org/hardhat-chai-matchers/docs/reference

const { expect } = require('chai');

const {
  ADDRESS_ZERO,
  ETH_FEED,
  BTC_FEED,
  BPS_DIVIDER,
  formatEvent,
  logReceipt,
  PRODUCTS,
  toUnits,
} = require('./utils.js');
const { setup } = require('./setup.js');

let loggingEnabled = false;

let _ = {}; // stores setup variables

// Used because _ is not ready when ordersToSubmit needs to be filled (script start), so fills retroactively
function fillAsset(val) {
  if (val == 'usdc') return _.usdc.address;
  return val;
}

// all valid orders
let ordersToSubmit = [
  {
    // index 0
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO,
    market: 'ETH-USD',
    margin: toUnits(0.5),
    size: toUnits(5),
    price: 0, // market order
    fee: 0,
    isLong: true, // long
    orderType: 0,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(1).add(toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER)), // margin + fee
  },
  {
    // index 1
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO,
    market: 'ETH-USD',
    margin: toUnits(0.5),
    size: toUnits(10),
    price: 0, // market order
    fee: 0,
    isLong: false, // short
    orderType: 0,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(10).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(0.5).add(toUnits(10).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER)), // margin + fee
  },
  {
    // index 2
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO,
    market: 'ETH-USD',
    margin: toUnits(1),
    size: toUnits(5),
    price: toUnits(1450), // limit order
    fee: 0,
    isLong: true, // long
    orderType: 1,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(1).add(toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER)), // margin + fee
  },
  {
    // index 3
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO,
    market: 'ETH-USD',
    margin: toUnits(5),
    size: toUnits(5),
    price: toUnits(1590), // limit order
    fee: 0,
    isLong: false, // short
    orderType: 1,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(5).add(toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER)), // margin + fee
  },
  {
    // index 4
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO,
    market: 'ETH-USD',
    margin: toUnits(2),
    size: toUnits(5),
    price: toUnits(1610), // stop order
    fee: 0,
    isLong: true, // long
    orderType: 2,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(2).add(toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER)), // margin + fee
  },
  {
    // index 5
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO,
    market: 'ETH-USD',
    margin: toUnits(3),
    size: toUnits(10),
    price: toUnits(1344), // stop order
    fee: 0,
    isLong: false, // short
    orderType: 2,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(10).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(3).add(toUnits(10).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER)), // margin + fee
  },
  {
    // index 6
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: 'usdc', // USDC
    market: 'ETH-USD',
    margin: toUnits(1000, 6),
    size: toUnits(5000, 6),
    price: 0, // market order
    fee: 0,
    isLong: true, // long
    orderType: 0,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5000, 6).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
  },
  {
    // index 7
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: 'usdc', // USDC
    market: 'ETH-USD',
    margin: toUnits(1000, 6),
    size: toUnits(5000, 6),
    price: toUnits(1622), // limit order
    fee: 0,
    isLong: false, // short
    orderType: 1,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5000, 6).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
  },
  {
    // index 8
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO, // ETH
    market: 'ETH-USD',
    margin: toUnits(2),
    size: toUnits(5),
    price: 0, // market order
    fee: 0,
    isLong: false, // short
    orderType: 0,
    isReduceOnly: true,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER), // fee only
  },
  {
    // index 9
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO, // ETH
    market: 'ETH-USD',
    margin: toUnits(2),
    size: toUnits(5),
    price: toUnits(1610), // stop order
    fee: 0,
    isLong: true, // short
    orderType: 2,
    isReduceOnly: true,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(2).add(toUnits(5).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER)), // margin + fee, sent extra, expect refund
  },
  {
    // index 10
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: 'usdc', // USDC
    market: 'ETH-USD',
    margin: 0,
    size: toUnits(5000, 6),
    price: toUnits(1544), // limit order
    fee: 0,
    isLong: true, // short
    orderType: 1,
    isReduceOnly: true,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5000, 6).mul(PRODUCTS['ETH-USD'].fee).div(BPS_DIVIDER),
  },
  {
    // index 11
    orderId: 0,
    user: ADDRESS_ZERO,
    asset: ADDRESS_ZERO,
    market: 'BTC-USD', // new market
    margin: toUnits(1),
    size: toUnits(5),
    price: 0, // market order
    fee: 0,
    isLong: true, // short
    orderType: 0,
    isReduceOnly: false,
    timestamp: 0,
    expiry: 0,
    cancelOrderId: 0,
    feeAmount: toUnits(5).mul(PRODUCTS['BTC-USD'].fee).div(BPS_DIVIDER),
    value: toUnits(1).add(toUnits(5).mul(PRODUCTS['BTC-USD'].fee).div(BPS_DIVIDER)), // margin + fee
  },
];

// Tests

describe('Trading', function () {
  before(async function () {
    if (_.provider) return;
    console.log('Initializing...');
    _ = await setup();

    console.log('Setting mock chainlink price...');

    await _.chainlink.setMarketPrice(ETH_FEED, toUnits(1500));

    // fill USDC address
    ordersToSubmit.forEach((o, i) => {
      ordersToSubmit[i].asset = fillAsset(o.asset);
    });

    console.log('Setup done...');

    // console.log('Mock chainlink price', await _.chainlink.getPrice(ADDRESS_ZERO));
  });

  describe('submitOrder', function () {
    describe('Should do error validations', async function () {
      it('Should not submit below min size', async function () {
        let tempOrder = { ...ordersToSubmit[0] };

        // set size below min size
        tempOrder.size = toUnits(0.001);

        // submit order, should revert
        await expect(_.orders.submitOrder(tempOrder, 0, 0, { value: tempOrder.value })).to.be.revertedWith('!min-size');
      });

      it('Should not submit unsupported asset', async function () {
        let tempOrder = { ...ordersToSubmit[6] };

        // unsupported asset
        tempOrder.asset = '0x000000000000000000000000000000000000dEaD';

        // submit order, should revert
        await expect(_.orders.submitOrder(tempOrder, 0, 0, { value: tempOrder.value })).to.be.revertedWith(
          '!asset-exists'
        );
      });
      it('Should not submit unsupported market', async function () {
        let tempOrder = { ...ordersToSubmit[0] };

        // unsupported market
        tempOrder.market = 'ETH-DAI';

        // submit order, should revert
        await expect(_.orders.submitOrder(tempOrder, 0, 0, { value: tempOrder.value })).to.be.revertedWith(
          '!market-exists'
        );
      });
      it('Should not submit below leverage = 1', async function () {
        let tempOrder = { ...ordersToSubmit[0] };

        // set size below margin
        let margin = tempOrder.margin;
        let subAmount = toUnits(0.1);
        tempOrder.size = margin.sub(subAmount);

        // submit order, should revert
        await expect(_.orders.submitOrder(tempOrder, 0, 0, { value: tempOrder.value })).to.be.revertedWith(
          '!min-leverage'
        );
      });
      it('Should not submit above max leverage', async function () {
        let tempOrder = { ...ordersToSubmit[0] };

        // set leverage to 1000
        let margin = tempOrder.margin;
        tempOrder.size = margin.mul(1000);

        // submit order, should revert
        await expect(_.orders.submitOrder(tempOrder, 0, 0, { value: tempOrder.value })).to.be.revertedWith(
          '!max-leverage'
        );
      });
      it('Should not submit if value is under required', async function () {
        // submit order, should revert
        await expect(_.orders.submitOrder(ordersToSubmit[0], 0, 0, { value: 0 })).to.be.reverted;
      });
      it('Should not submit tp below sl', async function () {
        // submit order, should revert
        await expect(
          _.orders.submitOrder(ordersToSubmit[0], toUnits(1400), toUnits(1600), { value: ordersToSubmit[0].value })
        ).to.be.revertedWith('!tpsl-invalid');
      });
      it('Should not submit order if new positions are paused', async function () {
        await _.orderStore.setAreNewOrdersPaused(true);

        await expect(
          _.orders.submitOrder(ordersToSubmit[0], toUnits(1400), toUnits(1600), {
            value: ordersToSubmit[0].value,
          })
        ).to.be.revertedWith('!paused');

        // unpause
        await _.orderStore.setAreNewOrdersPaused(false);
      });
    });
    ordersToSubmit.forEach((o, i) => {
      describe(`Should submit a new order on ${o.market} (order index=${i})`, async function () {
        let tx;

        const orderId = i + 1;

        it('Should submit successfully', async function () {
          // if (i == 9) console.log('Balance pre', await _.provider.getBalance(_.user1.address));

          tx = await _.orders.connect(_.user1).submitOrder(o, 0, 0, { value: o.value });

          receipt = await tx.wait();

          if (loggingEnabled) {
            logReceipt(receipt);
          }

          // if (i == 9) console.log('Balance post', await _.provider.getBalance(_.user1.address));

          expect(receipt.status).to.equal(1);
        });

        it('Should emit an OrderCreated event', async function () {
          await expect(tx)
            .to.emit(_.orders, 'OrderCreated')
            .withArgs(
              orderId,
              _.user1.address,
              o.asset,
              o.market,
              o.isLong,
              o.isReduceOnly ? 0 : o.margin,
              o.size,
              o.price,
              o.feeAmount,
              o.orderType,
              o.isReduceOnly,
              o.expiry,
              o.cancelOrderId
            );
        });

        it('Should expect balance change', async function () {
          let balanceSent = o.isReduceOnly ? 0 : o.margin.add(o.feeAmount);
          if (!o.isReduceOnly && o.asset == ADDRESS_ZERO) {
            await expect(tx).to.changeEtherBalance(_.user1, balanceSent.mul(-1));
          } else if (!o.isReduceOnly && o.asset == 'usdc') {
            await expect(tx).to.changeTokenBalance(_.usdc, _.user1, balanceSent.mul(-1));
          }
        });

        it('Should create new order object', async function () {
          const order = await _.orderStore.get(orderId);

          expect(order.market).to.equal(o.market);
          expect(order.size).to.equal(o.size);
          expect(order.timestamp).to.be.gt(0);
        });
      });
    });
  });
});
