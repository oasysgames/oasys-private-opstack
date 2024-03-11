#!/usr/bin/env bash

reqenv() {
  if [ -z "${!1}" ]; then
    echo "Error: environment variable '$1' is undefined"
    exit 1
  fi
}

deploy_addr () {
  echo -n $(jq -rM $1 /op-monorepo/packages/contracts-bedrock/tmp/oasys/L1/build/Deploy.s.sol/latest.json)
}

build_addr () {
  echo -n $(jq -rM $1 /op-monorepo/packages/contracts-bedrock/tmp/oasys/L1/build/Build.s.sol/latest/addresses.json)
}

reqenv L1_CHAIN_ID
reqenv OP_CHAIN_ID
reqenv L1_ETH_RPC_WS
reqenv OP_ETH_RPC_WS

yamlcode=$(cat << EOL
datastore: /data
keystore: /l1/validator/keystore

wallets:
  l1-validator1:
    address: '0xA889698683900857FA9AC54FBC972e88292b5387'

hub_layer:
  chain_id: $L1_CHAIN_ID
  rpc: $L1_ETH_RPC_WS

verse_layer:
  directs:
    - chain_id: $OP_CHAIN_ID
      rpc: $OP_ETH_RPC_WS
      l1_contracts:
        L2OutputOracle: '$(build_addr .L2OutputOracleProxy)'

p2p:
  listen: 0.0.0.0:4101
  no_announce: []
  connection_filter: []

verifier:
  enable: true
  wallet: l1-validator1

submitter:
  enable: true
  confirmations: 1
  l2oo_verifier_address: '$(deploy_addr .OasysL2OutputOracleVerifier)'
  targets:
    - chain_id: $OP_CHAIN_ID
      wallet: l1-validator1
EOL
)

echo "$yamlcode"
