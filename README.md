# Buckle App!

Live app --> https://buckle-app.vercel.app/

------------------------------

You're entering a novel use case of cross chain liquid staking protocol done with Chainlink ccip!

Users can bridge (and in the future swap) tokens without minting/burning tokens on source/destination chain.

_Buckle App...._

## Building in Public - Live Streaming Development

I live streamed on Youtube the development of Buckle. Every day, I was live designing, coding, testing the project until I completed it.

🥷🏻 follow me on [youtube](https://www.youtube.com/@fabriziogianni7) and [here you'll find the playlist](https://www.youtube.com/watch?v=iOLuLBu_egI&list=PLRWSSe23vY_tiReJzSOfDxgljIrnf0Lkk) of the live streaming.

## What is Buckle App

**Buckle** is a trustless cross chain bridge protocol operating with Chainlink ccip. It's inspired by the model of [atomic swaps](https://chain.link/education-hub/atomic-swaps), but it's much more.

Buckle App has its **Cross Chain Pools Pairs** where LPs can deposit Tokens and earn fees and other users can transfer their tokens from network to network. I replaced the term "bridge" with "teleport".

Buckle App is a trustless, automated atomic swap protocol, based on pools. Therefore we will call it **Cross Chain Pool Swap Protocol**.

> Anyone can create new cross chain pool pairs, and he need to give initial funding.

> The terms "bridge" and "swap" are replaced by the term "teleport"

## Protocol Risks

| Risk            | Degree        | Motivation                                                                      |
| --------------- | ------------- | ------------------------------------------------------------------------------- |
| Smart Contracts | Low           | Buckle is battle-tested and it will get audits in the future                    |
| Technology Risk | Low           | Based on CCIP which is decentralized                                            |
| Censorship Risk | Low           | Based on CCIP which is decentralized                                            |
| Liquidity Risk  | Not Dangerous | If there's no liquidity, users can't bridge                                     |
| Rug pull Risk   | Low           | LPs need to submit for a period of cooldown before removing liquidity, so the users that are bridging wont be rug-pulled|

## How does it Works (click on highlighted words to go to the code)
Buckle Is a protocol composed essentially by 2 smart contracts:
**CrossChainPool** and **PoolFactory**.

- [CrossChainPool](https://github.com/fabriziogianni7/buckle-app/blob/main/src/CrossChainPool.sol)
This is the contract that allow users to [teleport](https://github.com/fabriziogianni7/buckle-app/blob/197c1d1b2b2c32b95996618fea4abe2bf0b40121/src/CrossChainPool.sol#L334) tokens and LPs to [deposit](https://github.com/fabriziogianni7/buckle-app/blob/197c1d1b2b2c32b95996618fea4abe2bf0b40121/src/CrossChainPool.sol#L253C14-L253C21) tokens and [earn fees](https://github.com/fabriziogianni7/buckle-app/blob/197c1d1b2b2c32b95996618fea4abe2bf0b40121/src/CrossChainPool.sol#L282). *Each CrossChainPool is deployed and connected in pair with another pool on another chain*. the 2 pools can move 1 token from chain A to chain B.
When a user want to do a teleport, the pool uses ccip to send a simple message to the other pool.
Users deposit tokens supported by the pool in the pool on chain A. This one send a message to the pool on chain B telling to release the tokens to the address of the user. Users will receive the amount they bridged minus fees.
Users pay ccip fees in native currency.
*[Each pool has the count of how much tokens are in the pool on the other chain](https://github.com/fabriziogianni7/buckle-app/blob/197c1d1b2b2c32b95996618fea4abe2bf0b40121/src/CrossChainPool.sol#L103)*; this way it's not possible to teleport more than the amount available on the other pool.

- [PoolFactory](https://github.com/fabriziogianni7/buckle-app/blob/main/src/PoolFactory.sol)
This contract [deploys a pool pair with 1 transaction](https://github.com/fabriziogianni7/buckle-app/blob/197c1d1b2b2c32b95996618fea4abe2bf0b40121/src/PoolFactory.sol#L122). It uses a ccip message to do that.
The factory uses `CREATE2` opcode to create the new pool and to [compute the address of the pool that will be deployed on chain B](https://github.com/fabriziogianni7/buckle-app/blob/197c1d1b2b2c32b95996618fea4abe2bf0b40121/src/PoolFactory.sol#L142); then, it set it as allowed sender on the pool on chain A. when the message lands on chain B, the [receive function](https://github.com/fabriziogianni7/buckle-app/blob/197c1d1b2b2c32b95996618fea4abe2bf0b40121/src/PoolFactory.sol#L303) set the address of the deployed pool on chain A as allowed sender and actually deploy the pool we computed the address for on chain A 🥳.


## Contract Addresses (click on the address to see them verified on block explorers)

### Factories 
*Sepolia*: [0x01fdc7db792220246a7eb669a8f7b7cd79c3e870](https://sepolia.etherscan.io/address/0x01fdc7db792220246a7eb669a8f7b7cd79c3e870) 

*Arbitrum Sepolia*: [0x7f05a9166a3aad4983535e7da6d7dbcaf514e185](https://sepolia.arbiscan.io/address/0x7f05a9166a3aad4983535e7da6d7dbcaf514e185) 

*Avalanche Fuji-c*: [0x9c0a2c95646e32a764858fa95e30b7bd4d29cac2](https://testnet.snowtrace.io/address/0x9c0a2c95646e32a764858fa95e30b7bd4d29cac2) 

*Polygon Amoy*: [0xdbb077ddec08e8b574186098359d30556af6797d](https://amoy.polygonscan.com/address/0xdbb077ddec08e8b574186098359d30556af6797d) 

### Pools (will add more!)
*LINK pool arb <-> sepolia*: [0x7654336ca37b46839c780f52061c2d0406a7fb52](https://sepolia.arbiscan.io/address/0x7654336ca37b46839c780f52061c2d0406a7fb52) <-> [0xAdB5C1C087935D7bb1Bd973A9ba6401aB0151761](https://sepolia.etherscan.io/address/0xAdB5C1C087935D7bb1Bd973A9ba6401aB0151761)

*LINK pool arb <-> fuji*: [0x1037f2c9b532ec87aad224b2593a5589eae51098](https://sepolia.arbiscan.io/address/0x1037f2c9b532ec87aad224b2593a5589eae51098)  <-> [0x2Edde7A4f7A5d684CcE3c98D25A2F92042ef6C32](https://testnet.snowtrace.io/token/0x2Edde7A4f7A5d684CcE3c98D25A2F92042ef6C32?chainId=43113)

*LINK pool amoy <-> sepolia*: [0x17ecec2ab5977077d4c66f51fa7053b991e97fc4](https://amoy.polygonscan.com/address/0x17ecec2ab5977077d4c66f51fa7053b991e97fc4) <-> [0x4F3C6EF211f54B72DB1189F1339B31AD033B4F3D](https://sepolia.arbiscan.io/address/0x4F3C6EF211f54B72DB1189F1339B31AD033B4F3D)

