#!/usr/bin/env bash

# See: https://github.com/ethereum-optimism/optimism/blob/da4dfad5ab0c8f1e22cfd2b8d16e8b94bcfb969a/.envrc.example

reqenv() {
  if [ -z "${!1}" ]; then
    echo "Error: environment variable '$1' is undefined"
    exit 1
  fi
}

# Check required environment variables
reqenv "ENVRC_L1_RPC_URL"
reqenv "GS_ADMIN_ADDRESS"
reqenv "GS_ADMIN_PRIVATE_KEY"
reqenv "GS_BATCHER_ADDRESS"
reqenv "GS_BATCHER_PRIVATE_KEY"
reqenv "GS_PROPOSER_ADDRESS"
reqenv "GS_PROPOSER_PRIVATE_KEY"
reqenv "GS_SEQUENCER_ADDRESS"
reqenv "GS_SEQUENCER_PRIVATE_KEY"

# Generate the .envrc
envrc=$(cat << EOL
##################################################
#                 Getting Started                #
##################################################

# Admin account
export GS_ADMIN_ADDRESS=$GS_ADMIN_ADDRESS
export GS_ADMIN_PRIVATE_KEY=$GS_ADMIN_PRIVATE_KEY

# Batcher account
export GS_BATCHER_ADDRESS=$GS_BATCHER_ADDRESS
export GS_BATCHER_PRIVATE_KEY=$GS_BATCHER_PRIVATE_KEY

# Proposer account
export GS_PROPOSER_ADDRESS=$GS_PROPOSER_ADDRESS
export GS_PROPOSER_PRIVATE_KEY=$GS_PROPOSER_PRIVATE_KEY

# Sequencer account
export GS_SEQUENCER_ADDRESS=$GS_SEQUENCER_ADDRESS
export GS_SEQUENCER_PRIVATE_KEY=$GS_SEQUENCER_PRIVATE_KEY

##################################################
#              op-node Configuration             #
##################################################

# The kind of RPC provider, used to inform optimal transactions receipts
# fetching. Valid options: alchemy, quicknode, infura, parity, nethermind,
# debug_geth, erigon, basic, any.
export L1_RPC_KIND=basic

##################################################
#               Contract Deployment              #
##################################################
export L1_VERIFIER_URL=$ENVRC_L1_VERIFIER_URL

# RPC URL for the L1 network to interact with
export L1_RPC_URL=$ENVRC_L1_RPC_URL

# Salt used via CREATE2 to determine implementation addresses
# NOTE: If you want to deploy contracts from scratch you MUST reload this
#       variable to ensure the salt is regenerated and the contracts are
#       deployed to new addresses (otherwise deployment will fail)
export IMPL_SALT=\$(openssl rand -hex 32)

# Name for the deployed network
export DEPLOYMENT_CONTEXT=getting-started

# Optional Tenderly details for simulation link during deployment
export TENDERLY_PROJECT=
export TENDERLY_USERNAME=

# Optional Etherscan API key for contract verification
export ETHERSCAN_API_KEY=

# Private key to use for contract deployments, you don't need to worry about
# this for the Getting Started guide.
export PRIVATE_KEY=
EOL
)

# Print the .envrc
echo "$envrc"
