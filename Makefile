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
	@forge script script/DeployPoolFromFactory.s.sol  --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e -vvvv --sig "deploy(address,address,address,address,uint64,string)" 0x04722a980f2F48696446A3F3017520dCbe8527Cc 0x26bBdCc59D8c9d5f269635A1C13208d6DeE6d98e 0x3308ff248A0Aa6EB7499A39C4c26ADF526825B0d 0xDbb077Ddec08E8b574186098359d30556AF6797D 3478487238524512106 "GHOKEYTestPool" 


# Deploy factories on testnets
deploy-factory-arbitrum:
	@forge script script/DeployPoolFactory.s.sol --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e 

deploy-factory-sepolia:
	@forge script script/DeployPoolFactory.s.sol --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account deployer --sender 0x1C9E05B29134233e19fbd0FE27400F5FFFc3737e --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

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