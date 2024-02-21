#!/usr/bin/env bash

# See: https://github.com/ethereum-optimism/optimism/blob/da4dfad5ab0c8f1e22cfd2b8d16e8b94bcfb969a/.envrc.example

reqenv() {
  if [ -z "${!1}" ]; then
    echo "Error: environment variable '$1' is undefined"
    exit 1
  fi
}

# Check required environment variables
reqenv "CLIENT_L1_RPC_URL"
reqenv "ENVRC_L1_VERIFIER_URL"
reqenv "CLIENT_L2_RPC_URL"
reqenv "ENVRC_L2_VERIFIER_URL"
reqenv "L1_BLOCK_TIME"
reqenv "OP_CHAIN_ID"
reqenv "OP_BLOCK_TIME"
reqenv "OP_ADMIN_ADDR"
reqenv "OP_ADMIN_KEY"
reqenv "OP_BATCHER_ADDR"
reqenv "OP_BATCHER_KEY"
reqenv "OP_PROPOSER_ADDR"
reqenv "OP_PROPOSER_KEY"
reqenv "OP_SEQUENCER_ADDR"
reqenv "OP_SEQUENCER_KEY"

# Generate the .envrc
envrc=$(cat << EOL
##################################################
#                 Getting Started                #
##################################################

# Admin account
export OP_ADMIN_ADDR=$OP_ADMIN_ADDR
export OP_ADMIN_KEY=$OP_ADMIN_KEY

# Batcher account
export OP_BATCHER_ADDR=$OP_BATCHER_ADDR
export OP_BATCHER_KEY=$OP_BATCHER_KEY

# Proposer account
export OP_PROPOSER_ADDR=$OP_PROPOSER_ADDR
export OP_PROPOSER_KEY=$OP_PROPOSER_KEY

# Sequencer account
export OP_SEQUENCER_ADDR=$OP_SEQUENCER_ADDR
export OP_SEQUENCER_KEY=$OP_SEQUENCER_KEY

# For the "packages/contracts-bedrock/scripts/oasys/L1/build/Build.s.sol"
export FINAL_SYSTEM_OWNER=$OP_ADMIN_ADDR
export P2P_SEQUENCER=$OP_SEQUENCER_ADDR
export L2OO_CHALLENGER=$OP_ADMIN_ADDR
export L2OO_PROPOSER=$OP_PROPOSER_ADDR
export BATCH_SENDER=$OP_BATCHER_ADDR
export L2_CHAIN_ID=$OP_CHAIN_ID
export L1_BLOCK_TIME=$L1_BLOCK_TIME
export L2_BLOCK_TIME=$OP_BLOCK_TIME
export L2_GAS_LIMIT=$OP_GAS_LIMIT
export FINALIZATION_PERIOD_SECONDS=12
export OUTPUT_ORACLE_SUBMISSION_INTERVAL=120
export OUTPUT_ORACLE_STARTING_BLOCK_NUMBER=0
export OUTPUT_ORACLE_STARTING_TIMESTAMP=0
export ENABLE_L2_ZERO_FEE=true

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
export L2_VERIFIER_URL=$ENVRC_L2_VERIFIER_URL

# RPC URL for the L1 network to interact with
export L1_RPC_URL=$CLIENT_L1_RPC_URL
export L2_RPC_URL=$CLIENT_L2_RPC_URL

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
