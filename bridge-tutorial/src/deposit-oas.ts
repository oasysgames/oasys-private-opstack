import { program } from "commander";
import type { Overrides as TxOverrides } from "ethers";
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
    l1Address: l1Signer.address,
    l2Address: recipient,
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
  log("Deposit OAS to the L1StandardBridge...");

  const tx = await messenger.depositETH(amount.toString(), {
    recipient,
    overrides: { from: l1Signer.address } as TxOverrides,
  });
  const receipt = await tx.wait();
  await balance.update();

  log(
    "done",
    `    tx: ${tx.hash}`,
    `        (More: ${opsdk.l1Explorer}/tx/${tx.hash})`,
    `    balance on L1 : ${balance.current("l1", receipt)}`,
    `    balance on L2 : ${balance.current("l2")}\n\n`
  );

  /**
   * Step 2
   */
  log("Waiting for message to be relayed...");

  const start = new Date();
  await messenger.waitForMessageStatus(tx.hash, MessageStatus.RELAYED);
  await balance.update();

  const relayTx = await messenger.getMessageReceipt(tx.hash);
  log(
    `done (elapsed: ${(new Date().getTime() - start.getTime()) / 1000} sec)`,
    `    tx: ${relayTx.transactionReceipt.transactionHash}`,
    `        (More: ${opsdk.l2Explorer}/tx/${relayTx.transactionReceipt.transactionHash})`,
    `    balance on L1 : ${balance.current("l1")}`,
    `    balance on L2 : ${balance.current("l2")}`
  );
};

program
  .option("-r, --recipient <n>", "L2 Recipient address (default: sender)")
  .requiredOption("-a, --amount <n>", "Amount (unit: ether)")
  .showHelpAfterError();
program.parse();

main(program.opts<MainArgs>());
