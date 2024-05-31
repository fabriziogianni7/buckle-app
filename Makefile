-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil scopefile

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ANVIL_URL := http://127.0.0.1:8545

SEPOLIA_FACTORY := 0x01fdc7db792220246a7eb669a8f7b7cd79c3e870
ARB_SEPOLIA_FACTORY := 0x7f05a9166a3aad4983535e7da6d7dbcaf514e185
FUJI_FACTORY := 0x9c0a2c95646e32a764858fa95e30b7bd4d29cac2
AMOY_FACTORY := 0xdbb077ddec08e8b574186098359d30556af6797d

SEPOLIA_LINK := 0x779877A7B0D9E8603169DdbD7836e478b4624789
FUJI_LINK := 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
ARB_SEPOLIA_LINK := 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E
AMOY_LINK := 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904

ARB_SEPOLIA_CCIP_BNM := 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D
SEPOLIA_CCIP_BNM := 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05

SEPOLIA_CHAIN_ID:= 11155111
ARB_SEPOLIA_CHAIN_ID:= 421614
FUJI_CHAIN_ID:= 43113
AMOY_CHAIN_ID:= 80002

all: remove install build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit && forge install smartcontractkit/chainlink-local  --no-commit && forge install smartcontractkit/ccip@ff2bfce  --no-commit

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

## FROM SEPOLIA - link

  

deploy-pool-arb-to-sepolia-ccip-bnm:
	forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvvv --sig "deploy(address,address,address,address,uint256,string)"  ${ARB_SEPOLIA_FACTORY} ${SEPOLIA_FACTORY} ${ARB_SEPOLIA_CCIP_BNM} ${SEPOLIA_CCIP_BNM} ${SEPOLIA_CHAIN_ID} "LINKArbSepoliaSepolia"  --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --legacy


deploy-pool-arb-to-sepolia:
	forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvvv --sig "deploy(address,address,address,address,uint256,string)"  ${ARB_SEPOLIA_FACTORY} ${SEPOLIA_FACTORY} ${ARB_SEPOLIA_LINK} ${SEPOLIA_LINK} ${SEPOLIA_CHAIN_ID} "LINKArbSepoliaSepolia"  --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --legacy

deploy-pool-sepolia-to-arb:
	forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint256,string)" ${SEPOLIA_FACTORY} ${ARB_SEPOLIA_FACTORY} ${SEPOLIA_LINK} ${ARB_SEPOLIA_LINK} ${ARB_SEPOLIA_CHAIN_ID} "LINKSepoliArbSepolia" --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --legacy

deploy-pool-sepolia-to-fuji:	
	@forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint256,string)" ${SEPOLIA_FACTORY}  ${FUJI_FACTORY} ${SEPOLIA_LINK} ${FUJI_LINK} ${FUJI_CHAIN_ID} "LINKSepoliaFuji" --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --legacy

deploy-pool-fuji-to-arbitrum:	
	@forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${FUJI_C_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint256,string)" ${FUJI_FACTORY} ${ARB_SEPOLIA_FACTORY}    ${FUJI_LINK} ${ARB_SEPOLIA_LINK} ${ARB_SEPOLIA_CHAIN_ID} "LINKArbSepoliaFuji" --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --legacy


deploy-pool-sepolia-to-amoy:
	@forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint256,string)" ${SEPOLIA_FACTORY}  ${AMOY_FACTORY} ${SEPOLIA_LINK} ${AMOY_LINK} ${AMOY_CHAIN_ID} "LINKSepoliaAmoy" --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --legacy

#### FROM arbitrumsepolia

deploy-pool-arbsepolia-to-fuji:
	@forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint256,string)" ${ARB_SEPOLIA_FACTORY} ${FUJI_FACTORY} ${ARB_SEPOLIA_LINK} ${FUJI_LINK} ${FUJI_CHAIN_ID} "LINKArbSepoliaFuji" -vvvv --verify --etherscan-api-key verifyContract 

deploy-pool-amoy-to-sepolia:
	@forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${AMOY_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint256,string)" ${AMOY_FACTORY} ${SEPOLIA_FACTORY}   ${AMOY_LINK} ${SEPOLIA_LINK} ${SEPOLIA_CHAIN_ID} "LINKAmoyArbSepolia" 

deploy-pool-amoy-to-fuji:
	forge script script/deploy/DeployPoolFromFactory.s.sol  --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint256,string)" ${AMOY_FACTORY} ${FUJI_FACTORY} ${AMOY_LINK} ${FUJI_LINK} ${FUJI_CHAIN_ID} "LINKAmoyFuji" --verify --etherscan-api-key $(AMOYSCAN_API_KEY) -vvvvv 








deploy-pool-from-factory-arbitrum-to-fuji:
	@forge script script/DeployPoolFromFactory.s.sol  --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint64,string)" 0xa460Ec0F081f5F89F0420f2cb9A93760537ef7A5 0x54cCEe7e1eE9Aab153Da18b447a50D8282e1506F 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 14767482510784806043 "LINK_ARB_FUJI" 


# Deploy factories on testnets

deploy-factory-sepolia:
	@forge script script/deploy/DeployPoolFactory.s.sol --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv --legacy

deploy-factory-arbitrum:
	@forge script script/deploy/DeployPoolFactory.s.sol --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e --verify --etherscan-api-key $(ARBISCAN_API_KEY) -vvvv

deploy-factory-fuji:
	@forge script script/deploy/DeployPoolFactory.s.sol --rpc-url ${FUJI_C_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e  -vvvv --verify --etherscan-api-key verifyContract --legacy

deploy-factory-amoy:
	@forge script script/deploy/DeployPoolFactory.s.sol --rpc-url ${AMOY_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e  -vvvv --verify --etherscan-api-key $(AMOYSCAN_API_KEY) --legacy

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
	forge verify-contract 0x0c0d2bd3aff93ef5c1a628fe3d190994ec00c8d3 src/PoolFactory.sol:PoolFactory --verifier-url 'https://api-sepolia.etherscan.io/api' --etherscan-api-key $ETHERSCAN_API_KEY --num-of-optimizations 200 --compiler-version v0.8.25+commit.b61c2a91 --constructor-args $(cast abi-encode "constructor(address _ccipRouter, address _feeToken)" 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59 0x779877A7B0D9E8603169DdbD7836e478b4624789) --skip-is-verified-check --watch

verify-pool-sepolia:
	forge verify-contract 0x0c0d2bd3aff93ef5c1a628fe3d190994ec00c8d3 src/PoolFactory.sol:CrossChainPool --verifier-url 'https://api-sepolia.etherscan.io/api' --etherscan-api-key $ETHERSCAN_API_KEY --num-of-optimizations 200 --compiler-version v0.8.25+commit.b61c2a91 --constructor-args $(cast abi-encode "constructor(address _underlyingToken,string memory _name, uint64 _crossChainSelector, address _router, address _otherChainUnderlyingToken)" 0x779877A7B0D9E8603169DdbD7836e478b4624789 "LINKSepoliArbSepolia" 3478487238524512106 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E) --skip-is-verified-check --watch



#  make print-heading HEADING="PUBLIC FUNCTIONS"
print-heading:
	@heading="$(HEADING)"; \
	printf "/*//////////////////////////////////////////////////////////////\n"; \
	printf "                       %s\n" "$$heading"; \
	printf "//////////////////////////////////////////////////////////////*/\n"


