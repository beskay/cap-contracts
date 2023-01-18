# CAP v4 Solidity Contracts

basically if we have these by Monday

- General review and bug fixes
- Merge incrementClpSupply and incrementUserClpBalance
- Explore refactoring PositionLiquidated event with PositionDecreased
- Require Chainlink feed for added markets and disable changing the feed after a market is created
- Add constants to mitigate attack scenarios where keys are compromised. Max fee, max oracle fee, max chainlink deviation, max liqThreshold, max pool drawdown, etc.

plus some testing, we're good to go imo

## TODO
 
- [x] Merge `incrementClpSupply` and `incrementUserClpBalance`
- [ ] Explore refactoring `PositionLiquidated` event with `PositionDecreased`
- [x] Require Chainlink feed for added markets and disable changing the feed after a market is created
- [ ] Add constants to mitigate attack scenarios where keys are compromised. Max fee, max oracle fee, max chainlink deviation, max liqThreshold, max pool drawdown, etc.
- [ ] Add automated tests, including fuzzy, to achieve > 90% coverage
- [ ] Refactor and document code while maintaining readability
- [ ] Deploy and test locally with the [Client](https://github.com/capofficial/client) to make sure everything is working as expected
- [ ] Create / update local and production deploy scripts

## Compiling

```
npx hardhat compile
```

## Testing

TBD

Static code analysis with slither
```
slither .
```

## Deploying locally

```
npx hardhat node
npx hardhat run test --network localhost
```

(should be updated to use a dedicated local deploy script)

## Deploying

Set environment variables in .env (required in hardhat.config.js) and load them with
```
source .env
```
Example command to deploy and verify contracts on Arbitrum:
```
npx hardhat run scripts/deploy.js --network arbitrum
```