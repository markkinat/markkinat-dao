-include .env

fork-sepolia:
	@echo "Building broker binary..."
	@anvil --fork-url ${SEPOLIA_RPC_URL}


deploy-nft-sepolia:
	@echo "Deploying to sepolia..."
	@forge script ./script/MarkkinatNFTDeploy.s.sol --rpc-url ${SEPOLIA_RPC_URL}  --broadcast --private-key ${PRIVATE_KEY} --etherscan-api-key ${ETHERSCAN_KEY} --verify -vvvvv

deploy-dao-sepolia:
	@echo "Deploying to sepolia..."
	@forge script ./script/MarkkinatDAODeploy.s.sol --rpc-url ${SEPOLIA_RPC_URL}  --broadcast --private-key ${PRIVATE_KEY} --etherscan-api-key ${ETHERSCAN_KEY} --verify -vvvvv

test-dao:
	@echo "Testing fix..."
	@forge t --match-path test/MarkkinatGovernance.t.sol -vv

test-dao-verbose:
	@echo "Testing fix..."
	@forge t --match-path test/MarkkinatGovernance.t.sol -vvvvv

test-nft:
	@echo "Testing fix..."
	@forge t --match-path test/MarkkinatNFT.t.sol -vv

test-nft-verbose:
	@echo "Testing fix..."
	@forge t --match-path test/MarkkinatNFT.t.sol -vvvv





	
