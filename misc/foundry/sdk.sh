#!/usr/bin/env bash

reqenv() {
  if [ -z "${!1}" ]; then
    echo "Error: environment variable '$1' is undefined"
    exit 1
  fi
}

setenv () {
  VAR=$1
  export $VAR=$(jq -r .address  /op-monorepo/packages/contracts-bedrock/deployments/getting-started/$2.json)
}

setenv SDK_OP_ADDRESS_MANAGER_ADDRESS AddressManager
setenv SDK_OP_L1_MESSENGER_ADDRESS L1CrossDomainMessengerProxy
setenv SDK_OP_L1_BRIDGE_ADDRESS L1StandardBridgeProxy
setenv SDK_OP_PORTAL_ADDRESS OptimismPortalProxy
setenv SDK_OP_L2OO_ADDRESS L2OutputOracleProxy

reqenv "L1_CHAIN_ID"
reqenv "OP_CHAIN_ID"
reqenv "SDK_L1_RPC"
reqenv "SDK_L2_RPC"
reqenv "SDK_OP_ADDRESS_MANAGER_ADDRESS"
reqenv "SDK_OP_L1_MESSENGER_ADDRESS"
reqenv "SDK_OP_L1_BRIDGE_ADDRESS"
reqenv "SDK_OP_PORTAL_ADDRESS"
reqenv "SDK_OP_L2OO_ADDRESS"

jscode=$(cat << EOL
const ethers = require("ethers");
const optimismSDK = require("@eth-optimism/sdk");

const l1RPC = "$SDK_L1_RPC";
const l2RPC = "$SDK_L2_RPC";

const l1Contracts = {
  StateCommitmentChain: "0x0000000000000000000000000000000000000000",
  CanonicalTransactionChain: "0x0000000000000000000000000000000000000000",
  BondManager: "0x0000000000000000000000000000000000000000",
  AddressManager: "$SDK_OP_ADDRESS_MANAGER_ADDRESS",
  L1CrossDomainMessenger: "$SDK_OP_L1_MESSENGER_ADDRESS",
  L1StandardBridge: "$SDK_OP_L1_BRIDGE_ADDRESS",
  OptimismPortal: "$SDK_OP_PORTAL_ADDRESS",
  L2OutputOracle: "$SDK_OP_L2OO_ADDRESS",
};

/**
 * @param {Object} [args]
 * @param {string} [args.l1RPC]
 * @param {string} [args.l2RPC]
 */
const getProviders = (args) => {
  args = args || {}
  const l1Provider = new ethers.providers.JsonRpcProvider(args.l1RPC ?? l1RPC);
  const l2Provider = new ethers.providers.JsonRpcProvider(args.l2RPC ?? l2RPC);
  return { l1Provider, l2Provider };
};

/**
 * @param {Object} args
 * @param {ethers.BytesLike} args.privateKey
 * @param {ethers.ethers.providers.JsonRpcProvider} [args.l1Provider]
 * @param {ethers.ethers.providers.JsonRpcProvider} [args.l2Provider]
 */
const getSigners = (args) => {
  let { l1Provider, l2Provider } = args;
  if (!l1Provider || !l2Provider) {
    const providers = getProviders();
    l1Provider = l1Provider ?? providers.l1Provider;
    l2Provider = l2Provider ?? providers.l2Provider;
  }

  const l1Signer = new ethers.Wallet(args.privateKey).connect(l1Provider);
  const l2Signer = new ethers.Wallet(args.privateKey).connect(l2Provider);
  return { l1Signer, l2Signer };
};

/**
 * @param {Object} args
 * @param {optimismSDK.SignerOrProviderLike} args.l1Signer
 * @param {optimismSDK.SignerOrProviderLike} args.l2Signer
 * @param {optimismSDK.OEL1ContractsLike} [args.l1Contracts]
 */
const getCrossChainMessenger = (args) => {
  return new optimismSDK.CrossChainMessenger({
    bedrock: true,
    contracts: { l1: args.l1Contracts || l1Contracts },
    bridges: {
      Standard: {
        l1Bridge: l1Contracts.L1StandardBridge,
        l2Bridge: "0x4200000000000000000000000000000000000010",
        Adapter: optimismSDK.StandardBridgeAdapter,
      },
      ETH: {
        l1Bridge: l1Contracts.L1StandardBridge,
        l2Bridge: "0x4200000000000000000000000000000000000010",
        Adapter: optimismSDK.ETHBridgeAdapter,
      },
    },
    l1ChainId: $L1_CHAIN_ID,
    l2ChainId: $OP_CHAIN_ID,
    l1SignerOrProvider: args.l1Signer,
    l2SignerOrProvider: args.l2Signer,
  });
};

module.exports = { getProviders, getSigners, getCrossChainMessenger };
EOL
)

echo "$jscode"
