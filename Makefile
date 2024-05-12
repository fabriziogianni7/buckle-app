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

deploy-sepolia:
	@forge script script/DeployPoolFactory.s.sol --rpc-url ${ETHEREUM_SEPOLIA_RPC_URL} --broadcast --account notary3 --sender 0x39806bDCBd704970000Bd6DB4874D6e98cf15123 --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-arbitrum:
	@forge script script/DeployPoolFactory.s.sol --rpc-url ${ARBITRUM_SEPOLIA_RPC_URL} --broadcast --account notary3 --sender 0x39806bDCBd704970000Bd6DB4874D6e98cf15123 
