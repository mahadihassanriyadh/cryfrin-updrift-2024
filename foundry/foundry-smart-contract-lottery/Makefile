-include .env

# .PHONY is a special target in Makefiles, used to declare that the targets are not associated with any files.
.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean:; forge clean

build:; forge build

test:; forge test 

snapshot:; forge snapshot

format:; forge fmt

anvil:; anvil

NETWORK_ARGS := --rpc-url $(ANVIL_RPC_URL) --account $(ANVIL_ACCOUNT) --sender $(ANVIL_PUBLIC_KEY) --broadcast -vvvvv

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --sender $(SEPOLIA_PUBLIC_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvvv
else ifeq ($(findstring --network ganache,$(ARGS)),--network ganache)
	NETWORK_ARGS := --rpc-url $(GANACHE_RPC_URL) --account $(GNACHE_ACCOUNT) --sender $(GANACHE_PUBLIC_KEY) --broadcast -vvvvv
endif

deploy:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)

fund:
	@forge script script/Interactions.s.sol:FundFundMe $(NETWORK_ARGS)

withdraw:
	@forge script script/Interactions.s.sol:WithdrawFundMe $(NETWORK_ARGS)

deploy-fundMe-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --sender $(SEPOLIA_PUBLIC_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvvv