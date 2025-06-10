.PHONY: install
install:
	forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts --no-git

.PHONY: deploy
deploy:
forge create \
	--rpc-url $RPC_URL \
	--private-key $PRIVATE_KEY \
	--chain 10143 \
	--verify \
	--verifier sourcify \
	--verifier-url https://sourcify-api-monad.blockvision.org \
	script/deployer.sol:Deployer