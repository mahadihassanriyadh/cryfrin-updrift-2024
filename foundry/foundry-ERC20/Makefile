-include .env

# .PHONY is a special target in Makefiles, used to declare that the targets are not associated with any files.
.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo "\n\nGit Commit & Push:"
	@echo "  make commit m=\"commit message\""

all: @clean remove install update build

# Clean the repo
clean:; @forge clean

build:; @forge build

install:; @forge install Cyfrin/foundry-devops@0.1.0 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@0.8.0 --no-commit && forge install transmissions11/solmate@v6 --no-commit && forge install foundry-rs/forge-std@v1.7.6 --no-commit

test:; @forge test 

snapshot:; @forge snapshot

format:; @forge fmt

# just running `anvil` will start a local anvil instance as well, but the extra flags are for debugging purposes
anvil :; @anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url $(ANVIL_RPC_URL) --account $(ANVIL_ACCOUNT) --sender $(ANVIL_PUBLIC_KEY) --broadcast -vvvv

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --sender $(SEPOLIA_PUBLIC_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
else ifeq ($(findstring --network ganache,$(ARGS)),--network ganache)
	NETWORK_ARGS := --rpc-url $(GANACHE_RPC_URL) --account $(GNACHE_ACCOUNT) --sender $(GANACHE_PUBLIC_KEY) --broadcast -vvvv
endif

deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

fund:
	@forge script script/Interactions.s.sol:FundFundMe $(NETWORK_ARGS)

withdraw:
	@forge script script/Interactions.s.sol:WithdrawFundMe $(NETWORK_ARGS)

coverage-report:; @forge coverage --report debug > test-coverage.txt

commit:
	git add -A
	git commit -s -m "$(m)"
	git push