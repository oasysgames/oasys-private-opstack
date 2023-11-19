import { program } from "commander";
import { MessageStatus } from "@eth-optimism/sdk";
import { Ether, BalanceLogger, log } from "./lib";
import * as opsdk from "./lib/sdk";

// Setup the OP Stack SDK
const privateKey = process.env.PRIVATE_KEY!;
const { l1Signer, l2Signer } = opsdk.getSigners({ privateKey });
const messenger = opsdk.getCrossChainMessenger({ l1Signer, l2Signer });

// Main
type MainArgs = { amount: string; recipient?: string };

const main = async (args: MainArgs) => {
  const amount = BigInt(args.amount) * Ether;
  const recipient = args.recipient ?? l1Signer.address;

  const balance = new BalanceLogger({
    ...opsdk.getProviders(),
    l1Address: recipient,
    l2Address: l2Signer.address,
  });
  await balance.update();

  log(
    "Initial Balance",
    `    balance on L1 : ${balance.current("l1")}`,
    `    balance on L2 : ${balance.current("l2")}\n\n`
  );

  /**
   * Step 1
   */
  log("Transfer and Burn OAS to the L2StandardBridge...");

  let tx = await messenger.withdrawETH(amount.toString(), { recipient });
  let receipt = await tx.wait();
  await balance.update();

  log(
    "done",
    `    tx: ${tx.hash}`,
    `        (More: ${opsdk.l2Explorer}/tx/${tx.hash})`,
    `    balance on L1 : ${balance.current("l1")}`,
    `    balance on L2 : ${balance.current("l2", receipt)}\n\n`
  );

  const withdrawTxHash = tx.hash;

  /**
   * Step 2
   */
  log(
    "Waiting for message status to be `READY_TO_PROVE`, Takes up to 10 minutes..."
  );

  let start = new Date();
  await messenger.waitForMessageStatus(
    withdrawTxHash,
    MessageStatus.READY_TO_PROVE
  );

  log(
    `done (elapsed: ${(new Date().getTime() - start.getTime()) / 1000} sec)\n\n`
  );

  /**
   * Step 3
   */
  log("Sending a prove message to the OptimismPortal...");

  tx = await messenger.proveMessage(withdrawTxHash);
  receipt = await tx.wait();
  await balance.update();

  log(
    "done",
    `    tx: ${tx.hash}`,
    `        (More: ${opsdk.l1Explorer}/tx/${tx.hash})`,
    `    balance on L1 : ${balance.current("l1", receipt)}`,
    `    balance on L2 : ${balance.current("l2")}\n\n`
  );

  /**
   * Step 4
   */
  log(
    "In the challenge period, Waiting for message status to be `READY_FOR_RELAY`..."
  );

  start = new Date();
  await messenger.waitForMessageStatus(
    withdrawTxHash,
    MessageStatus.READY_FOR_RELAY
  );

  log(
    `done (elapsed: ${(new Date().getTime() - start.getTime()) / 1000} sec)\n\n`
  );

  /**
   * Step 5
   */
  log("Sending a finalizing message to the OptimismPortal...");

  tx = await messenger.finalizeMessage(withdrawTxHash);
  receipt = await tx.wait();

  log(
    "done",
    `    tx: ${tx.hash}`,
    `        (More: ${opsdk.l1Explorer}/tx/${tx.hash})\n\n`
  );

  /**
   * Step 6
   */
  log("Waiting for message status to be `RELAYED`...");

  start = new Date();
  await messenger.waitForMessageStatus(withdrawTxHash, MessageStatus.RELAYED);
  await balance.update();

  log(
    `done (elapsed: ${(new Date().getTime() - start.getTime()) / 1000} sec)`,
    `    balance on L1 : ${balance.current("l1", receipt)}`,
    `    balance on L2 : ${balance.current("l2")}`
  );
};

program
  .option("-r, --recipient <n>", "L2 Recipient address (default: sender)")
  .requiredOption("-a, --amount <n>", "Amount (unit: ether)")
  .showHelpAfterError();
program.parse();

main(program.opts<MainArgs>());
