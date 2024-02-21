import * as opsdk from "./lib/sdk";

const privateKey = process.env.PRIVATE_KEY!;

const { l1Provider, l2Provider } = opsdk.getProviders();
const { l1Signer, l2Signer } = opsdk.getSigners({ privateKey, l1Provider, l2Provider });
const crossChainMessenger = opsdk.getCrossChainMessenger({ l1Signer, l2Signer });

console.log(crossChainMessenger)
