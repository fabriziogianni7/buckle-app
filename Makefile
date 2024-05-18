-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil scopefile

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ANVIL_URL := http://127.0.0.1:8545

all: remove install build

# Clean the repo
clean  :; forge clean

# Remove modules
# remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

slither :; slither . --config-file slither.config.json --checklist 

aderyn :; aderyn .

scopefile :; @tree ./src/ | sed 's/└/#/g' | awk -F '── ' '!/\.sol$$/ { path[int((length($$0) - length($$2))/2)] = $$2; next } { p = "src"; for(i=2; i<=int((length($$0) - length($$2))/2); i++) if (path[i] != "") p = p "/" path[i]; print p "/" $$2; }' > scope.txt

scope :; tree ./src/ | sed 's/└/#/g; s/──/--/g; s/├/#/g; s/│ /|/g; s/│/|/g'

deploy-anvil:
	 @forge script script/DeployPoolFactory.s.sol --rpc-url ${ANVIL_URL} --broadcast --account anvilAcc


deploy-pool-from-factory-sepolia:
	@forge script script/DeployPoolFromFactory.s.sol  --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint64,string)" 0x78f2aA2F6A8B92a0539bA56dDEcfFc0c18e4fEBD 0xa460Ec0F081f5F89F0420f2cb9A93760537ef7A5 0x3308ff248A0Aa6EB7499A39C4c26ADF526825B0d 0xDbb077Ddec08E8b574186098359d30556AF6797D 3478487238524512106 "GHOKEYTestPool" 

deploy-pool-from-factory-arbitrum-to-fuji:
	@forge script script/DeployPoolFromFactory.s.sol  --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint64,string)" 0xa460Ec0F081f5F89F0420f2cb9A93760537ef7A5 0x54cCEe7e1eE9Aab153Da18b447a50D8282e1506F 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 14767482510784806043 "LINK_ARB_FUJI" 


# Deploy factories on testnets
deploy-factory-arbitrum:
	@forge script script/DeployPoolFactory.s.sol --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-factory-sepolia:
	@forge script script/DeployPoolFactory.s.sol --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e --verify --etherscan-api-key $(ARBISCAN_API_KEY) -vvvv

deploy-factory-fuji:
	@forge script script/DeployPoolFactory.s.sol --rpc-url ${FUJI_C_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e  -vvvv --verify --etherscan-api-key verifyContract

# command on forked networks
# using local forked network url
fork-sepolia:
	anvil --fork-url ${ETHEREUM_SEPOLIA_RPC_URL} 
fork-arbitrum:
	anvil --fork-url ${ARBITRUM_SEPOLIA_RPC_URL} --port 8546

deploy-sepolia-forked:
	@forge script script/DeployPoolFactory.s.sol --rpc-url 127.0.0.1:8545 --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv

deploy-arbitrum-forked:
	@forge script script/DeployPoolFactory.s.sol --rpc-url 127.0.0.1:8546 --broadcast --account arbDeployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv



# change the address of the factory
withdraw-link-sepolia:
	@forge script script/RedeemLink.s.sol:RedeemLink  --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvvv --sig "redeem(address)" 0x40ed5256EC8E69D2E9bc4781c27e5b833589Dc0f

withdraw-link-arbitrum:
	@forge script script/RedeemLink.s.sol:RedeemLink  --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvvv --sig "redeem(address)" 0xecA742215f77db3723056d1cAD9F09D06F37F129


# factory verification (modify arguments)
verify-factory-fuji:
	forge verify-contract 0x6954D9e3DB092BCE5B10cAf4ab78aE8d538ff38a src/PoolFactory.sol:PoolFactory --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key verifyContract --num-of-optimizations 200 --compiler-version v0.8.25+commit.b61c2a91 --constructor-args $(cast abi-encode "constructor(address _ccipRouter, address _feeToken)" 0xF694E193200268f9a4868e4Aa017A0118C9a8177 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846) --skip-is-verified-check --watch

verify-factory-arb:
	forge verify-contract 0xa460Ec0F081f5F89F0420f2cb9A93760537ef7A5 src/PoolFactory.sol:PoolFactory --verifier-url 'https://api-sepolia.arbiscan.io/api' --etherscan-api-key ${ARBISCAN_API_KEY} --num-of-optimizations 200 --compiler-version v0.8.25+commit.b61c2a91 --constructor-args $(cast abi-encode "constructor(address _ccipRouter, address _feeToken)" 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E) --skip-is-verified-check --watch

verify-factory-sepolia:
	forge verify-contract 0x78f2aA2F6A8B92a0539bA56dDEcfFc0c18e4fEBD src/PoolFactory.sol:PoolFactory --verifier-url 'https://api-sepolia.etherscan.io/api' --etherscan-api-key $ETHERSCAN_API_KEY --num-of-optimizations 200 --compiler-version v0.8.25+commit.b61c2a91 --constructor-args $(cast abi-encode "constructor(address _ccipRouter, address _feeToken)" 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59 0x779877A7B0D9E8603169DdbD7836e478b4624789) --skip-is-verified-check --watch

