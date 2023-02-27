# Getting Started with CrowdFunding

## Running the contract

1. From the root directory, rename the file `secrets.placeholder.json` to `secrets.json` and ensure that the `alchemyApiKey` key contains the secret API key that was shared with you.
2. Run `npm i`
3. Run `npm run start-local-blockchain`
4. Run `npm test`

## Available Scripts

In the project directory, you can run:

### `npm run start-local-blockchain`

It starts a hardhat local blockchain for development purposes.

### `npm test`

Launches the test runner and runs all the tests.

Use this script to run the entire flow.

### `npm run start-hardhat-console`

Opens the interactive hardhat console.

### `npm run create`

It deploys the smart contract.

### `npm run upgrade`

It ugrades the smart contract using UUPS.

### `npm run slither`

It runs slither to find security vulnerabilities.
It requires manual installation of dependencies.
