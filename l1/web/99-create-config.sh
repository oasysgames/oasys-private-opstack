#!/bin/sh

config=$(cat << EOL
const config = {
  l1: {
    chainId: $L1_CHAIN_ID,
    rpc: '$L1_RPC',
    explorer: '$L1_EXPLORER',
  },
  op: {
    chainId: $OP_CHAIN_ID,
    rpc: '$OP_RPC',
    explorer: '$OP_EXPLORER',
  },
  faucet: {
    address: '0x708c87fBbec51DE4EDa4E18A872222648316BCB5',
    key: '0x9ae97161da58263758cc57459bc39252bab369893324d401cb5abe2f6e2e6ce4',
  },
  contracts: {
    environment: '0x0000000000000000000000000000000000001000',
    stakemanager: '0x0000000000000000000000000000000000001001',
    candidatemanager: '0x520000000000000000000000000000000000002e',
  },
  validators: [
    {
      name: 'validator1',
      ownerKey: '0x92643dfbc8573869fe5dfeee88dc80ebb320ec60b63705bbbada7ec3fe2c6bfe',
      operator: '0xA889698683900857FA9AC54FBC972e88292b5387',
      verifier: true,
    },
    {
      name: 'validator2',
      ownerKey: '0xf5e95eb3a1f5e40689dea73bb4e8bab3d37684de6a881c12efe24f6ce506409b',
      operator: '0xB07F340E051cc0db4d9d4fD115B148993994DddD',
    },
    {
      name: 'validator3',
      ownerKey: '0x3da6e34cbe2db96e74ab22269cfa22fde7badd670550d759917d606866beb485',
      operator: '0x9a8490E0faE649cA0ED0b221E4FadCa9a44Cd93e',
    }
  ]
}
EOL
)

echo "$config" > /usr/share/nginx/html/config.js
