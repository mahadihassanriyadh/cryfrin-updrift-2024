-include .env

build:; forge build

deploy-fundMe-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --sender $(SEPOLIA_PUBLIC_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvvv