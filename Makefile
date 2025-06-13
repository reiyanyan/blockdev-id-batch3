.PHONY: install
install:
	forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts --no-git

.PHONY: deploy
deploy:
	set +a; \
	source .env; \
	set -a; \
	forge script \
	--rpc-url $$RPC_URL \
	--private-key $$PRIVATE_KEY \
	--broadcast \
	--chain 10143 \
	--verify \
	--verifier sourcify \
	--verifier-url https://sourcify-api-monad.blockvision.org \
	script/deployer.sol:Deployer