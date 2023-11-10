#!/usr/bin/env bash

# See: https://github.com/ethereum-optimism/optimism/blob/da4dfad5ab0c8f1e22cfd2b8d16e8b94bcfb969a/packages/contracts-bedrock/scripts/getting-started/config.sh

# This script is used to generate the getting-started.json configuration file
# used in the Getting Started quickstart guide on the docs site. Avoids the
# need to have the getting-started.json committed to the repo since it's an
# invalid JSON file when not filled in, which is annoying.

reqenv() {
  if [ -z "${!1}" ]; then
    echo "Error: environment variable '$1' is undefined"
    exit 1
  fi
}

# Check required environment variables
reqenv "L1_RPC_URL"
reqenv "L1_CHAIN_ID"
reqenv "L1_BLOCK_TIME"
reqenv "OP_CHAIN_ID"
reqenv "OP_BLOCK_TIME"
reqenv "GS_ADMIN_ADDRESS"
reqenv "GS_BATCHER_ADDRESS"
reqenv "GS_PROPOSER_ADDRESS"
reqenv "GS_SEQUENCER_ADDRESS"
reqenv "GS_BATCH_INBOX_ADDRESS"

# Get the finalized block timestamp and hash
block=$(cast block latest --rpc-url $L1_RPC_URL)
timestamp=$(echo "$block" | awk '/timestamp/ { print $2 }')
blockhash=$(echo "$block" | awk '/hash/ { print $2 }')

# Generate the config
config=$(cat << EOL
{
  "finalSystemOwner": "$GS_ADMIN_ADDRESS",
  "portalGuardian": "$GS_ADMIN_ADDRESS",

  "l1StartingBlockTag": "$blockhash",

  "l1ChainID": $L1_CHAIN_ID,
  "l2ChainID": $OP_CHAIN_ID,
  "l2BlockTime": $OP_BLOCK_TIME,
  "l1BlockTime": $L1_BLOCK_TIME,

  "maxSequencerDrift": 600,
  "sequencerWindowSize": 3600,
  "channelTimeout": 300,

  "p2pSequencerAddress": "$GS_SEQUENCER_ADDRESS",
  "batchInboxAddress": "$GS_BATCH_INBOX_ADDRESS",
  "batchSenderAddress": "$GS_BATCHER_ADDRESS",

  "l2OutputOracleSubmissionInterval": 120,
  "l2OutputOracleStartingBlockNumber": 0,
  "l2OutputOracleStartingTimestamp": $timestamp,

  "l2OutputOracleProposer": "$GS_PROPOSER_ADDRESS",
  "l2OutputOracleChallenger": "$GS_ADMIN_ADDRESS",

  "finalizationPeriodSeconds": 12,

  "proxyAdminOwner": "$GS_ADMIN_ADDRESS",
  "baseFeeVaultRecipient": "$GS_ADMIN_ADDRESS",
  "l1FeeVaultRecipient": "$GS_ADMIN_ADDRESS",
  "sequencerFeeVaultRecipient": "$GS_ADMIN_ADDRESS",

  "baseFeeVaultMinimumWithdrawalAmount": "0x8ac7230489e80000",
  "l1FeeVaultMinimumWithdrawalAmount": "0x8ac7230489e80000",
  "sequencerFeeVaultMinimumWithdrawalAmount": "0x8ac7230489e80000",
  "baseFeeVaultWithdrawalNetwork": 0,
  "l1FeeVaultWithdrawalNetwork": 0,
  "sequencerFeeVaultWithdrawalNetwork": 0,

  "gasPriceOracleOverhead": 2100,
  "gasPriceOracleScalar": 1000000,

  "enableGovernance": true,
  "governanceTokenSymbol": "OP",
  "governanceTokenName": "Optimism",
  "governanceTokenOwner": "$GS_ADMIN_ADDRESS",

  "l2GenesisBlockGasLimit": "0x1c9c380",
  "l2GenesisBlockBaseFeePerGas": "0x3b9aca00",
  "l2GenesisRegolithTimeOffset": "0x0",

  "eip1559Denominator": 50,
  "eip1559DenominatorCanyon": 250,
  "eip1559Elasticity": 10,

  "systemConfigStartBlock": 0,

  "requiredProtocolVersion": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "recommendedProtocolVersion": "0x0000000000000000000000000000000000000000000000000000000000000000"
}
EOL
)

# Print the config
echo "$config"
