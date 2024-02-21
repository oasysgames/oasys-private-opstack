import * as opsdk from "./lib/sdk";

const privateKey = process.env.PRIVATE_KEY!;

const { l1Provider, l2Provider } = opsdk.getProviders();
const { l1Signer, l2Signer } = opsdk.getSigners({ privateKey, l1Provider, l2Provider });
const crossChainMessenger = opsdk.getCrossChainMessenger({ l1Signer, l2Signer });

async function main() {
  const receipt = await l1Provider.getTransactionReceipt("0x0ae18e40291694cfad2104a222bf2184964936544dffa1dfdf3634ea565785d6");
  console.log(receipt);
}

main().catch((error) => {
  console.error("Error in main execution:", error);
});

