# ZOOMER xERC20

## What is ZOOMER xERC20?
[$ZOOMER](https://zoomer.money) is the most bussin coin in existence fr fr. The based ZOOMER devs have decided to make ZOOMER an [xERC20](https://ethereum-magicians.org/t/erc-7281-sovereign-bridged-tokens/14979) token, embracing the open standard for cross-chain ERC20 tokens.

This repo is the home of the ZOOMER xERC20 contracts which illustrate how to implement the xERC20 standard and deploy it in an upgradable way to allow for future updates to the standard before it is finalized.

## Testing
To run the tests, first install the dependencies:
```
npm install
```

Then run the tests:
```
npm test
```

Tests for the contract functionality are written in Forge, and the upgrade tests are written in Hardhat. 

## Deploying
To deploy the contracts, first install the dependencies:
```
npm install
```

Then run the deployment script (example for Arbitrum):
```
npx hardhat run scripts/deploy.ts --network arbitrum
```

Note this is a minimal repo and configs need to be added for other networks. See the [Hardhat docs](https://hardhat.org/config/) for more info.