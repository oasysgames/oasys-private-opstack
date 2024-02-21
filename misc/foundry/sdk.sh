#!/usr/bin/env bash

reqenv() {
  if [ -z "${!1}" ]; then
    echo "Error: environment variable '$1' is undefined"
    exit 1
  fi
}

setenv () {
  KEY=$1
  VAR=$2
  export $VAR=$(jq -rM $KEY /op-monorepo/packages/contracts-bedrock/tmp/oasys/L1/build/Build.s.sol/latest/addresses.json)
}

setenv .L1CrossDomainMessengerProxy OP_L1_CROSS_DOMAIN_MESSENGER_ADDR
setenv .L1StandardBridgeProxy OP_L1_STANDARD_BRIDGE_ADDR
setenv .L1ERC721BridgeProxy OP_L1_ERC721_BRIDGE_ADDR
setenv .OptimismPortalProxy OP_OPTIMISM_PORTAL_ADDR
setenv .L2OutputOracleProxy OP_L2OO_ADDR
setenv .AddressManager OP_ADDRESS_MANAGER_ADDR

reqenv L1_CHAIN_ID
reqenv OP_CHAIN_ID
reqenv L1_ETH_RPC_HTTP_PORT
reqenv OP_ETH_RPC_HTTP_PORT
reqenv OP_MONO_REPO
reqenv L1_BLOCKSCOUT_PORT
reqenv OP_BLOCKSCOUT_PORT
reqenv OP_L1_CROSS_DOMAIN_MESSENGER_ADDR
reqenv OP_L1_STANDARD_BRIDGE_ADDR
reqenv OP_L1_ERC721_BRIDGE_ADDR
reqenv OP_OPTIMISM_PORTAL_ADDR
reqenv OP_L2OO_ADDR
reqenv OP_ADDRESS_MANAGER_ADDR

jscode=$(cat << EOL
const ethers = require("ethers");
const optimismSDK = require("$OP_MONO_REPO/packages/sdk");

const l1RPC = "http://127.0.0.1:$L1_ETH_RPC_HTTP_PORT";
const l2RPC = "http://127.0.0.1:$OP_ETH_RPC_HTTP_PORT";

const l1Explorer = "http://127.0.0.1:$L1_BLOCKSCOUT_PORT";
const l2Explorer = "http://127.0.0.1:$OP_BLOCKSCOUT_PORT";

const l1Contracts = {
  StateCommitmentChain: "0x0000000000000000000000000000000000000000",
  CanonicalTransactionChain: "0x0000000000000000000000000000000000000000",
  BondManager: "0x0000000000000000000000000000000000000000",
  AddressManager: "$OP_ADDRESS_MANAGER_ADDR",
  L1CrossDomainMessenger: "$OP_L1_CROSS_DOMAIN_MESSENGER_ADDR",
  L1StandardBridge: "$OP_L1_STANDARD_BRIDGE_ADDR",
  L1ERC721BridgeProxy: "$OP_L1_ERC721_BRIDGE_ADDR",
  OptimismPortal: "$OP_OPTIMISM_PORTAL_ADDR",
  L2OutputOracle: "$OP_L2OO_ADDR",
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
 * @param {Object} [args.bridgeAdapter]
 * @param {new (opts: {
 *   messenger: optimismSDK.CrossChainMessenger;
 *   l1Bridge: optimismSDK.AddressLike;
 *   l2Bridge: optimismSDK.AddressLike
* }) => optimismSDK.IBridgeAdapter} args.bridgeAdapter.adapter
 * @param {string} args.bridgeAdapter.l1Bridge
 * @param {string} args.bridgeAdapter.l2Bridge
 */
const getCrossChainMessenger = (args) => {
  let bridgeAdapter = {
    Adapter: optimismSDK.StandardBridgeAdapter,
    l1Bridge: l1Contracts.L1StandardBridge,
    l2Bridge: "0x4200000000000000000000000000000000000010",
  }
  if (args.bridgeAdapter) {
    bridgeAdapter = {
      Adapter: args.bridgeAdapter.adapter,
      l1Bridge: args.bridgeAdapter.l1Bridge,
      l2Bridge: args.bridgeAdapter.l2Bridge,
    }
  }

  return new optimismSDK.CrossChainMessenger({
    bedrock: true,
    contracts: { l1: args.l1Contracts || l1Contracts },
    bridges: { Standard: bridgeAdapter },
    l1ChainId: $L1_CHAIN_ID,
    l2ChainId: $OP_CHAIN_ID,
    l1SignerOrProvider: args.l1Signer,
    l2SignerOrProvider: args.l2Signer,
  });
};

module.exports = {
  l1RPC,
  l2RPC,
  l1Explorer,
  l2Explorer,
  l1Contracts,
  getProviders,
  getSigners,
  getCrossChainMessenger,
};
EOL
)

echo "$jscode"
