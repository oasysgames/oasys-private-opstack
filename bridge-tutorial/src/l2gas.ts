import { program } from "commander";
import { MessageStatus } from "@eth-optimism/sdk";
import { Ether, BalanceLogger, log } from "./lib";
import * as opsdk from "./lib/sdk";

// Setup the OP Stack SDK
const privateKey = process.env.PRIVATE_KEY!;
const { l1Signer, l2Signer } = opsdk.getSigners({ privateKey });
const messenger = opsdk.getCrossChainMessenger({ l1Signer, l2Signer });


const main = async () => {
  const amount = BigInt(1) * Ether;
  const recipient = l1Signer.address;

  const data = await l2Signer.provider.getFeeData()
  console.log(data)

  const block = await l2Signer.provider.getBlock("latest")
  if (block && block.baseFeePerGas) {
    console.log(block)
  }

  let tx = await l2Signer.sendTransaction({ to: recipient, value: 0, maxPriorityFeePerGas: 0, maxFeePerGas: 0 });

  // record start time
  const start = Date.now();

  let receipt = await tx.wait(1);
  // let receipt = await wait(tx);
  // record end time
  const end = Date.now();

  // print the time it took to send the transaction
  console.log(`Time to send transaction: ${end - start}ms`);

  console.log(receipt)
};

// function wait until receipt returns
const wait = async (tx: any) => {
  let receipt;
  while(!receipt) {
    // retrieve the transaction receipt
    receipt = await l2Signer.provider.getTransactionReceipt(tx.hash);

  }
  return receipt;
};


main();
