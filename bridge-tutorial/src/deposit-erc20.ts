import { program } from "commander";
import { BigNumber, Contract } from "ethers";
import { MessageStatus } from "@eth-optimism/sdk";
import { Ether, ERC20ABI, log } from "./lib";
import * as opsdk from "./lib/sdk";

// Setup the OP Stack SDK
const privateKey = process.env.PRIVATE_KEY!;
const { l1Signer, l2Signer } = opsdk.getSigners({ privateKey });
const messenger = opsdk.getCrossChainMessenger({ l1Signer, l2Signer });

// Main
type MainArgs = {
  l1Token: string;
  l2Token: string;
  amount: string;
  recipient?: string;
};

const main = async (args: MainArgs) => {
  const amount = BigInt(args.amount) * Ether;
  const recipient = args.recipient ?? l1Signer.address;

  const l1Token = new Contract(args.l1Token, [ERC20ABI], l1Signer.provider);
  const l2Token = new Contract(args.l2Token, [ERC20ABI], l2Signer.provider);

  const reportBalance = async (): Promise<string[]> => {
    const l1 = (await l1Token.functions.balanceOf(recipient))[0] as BigNumber;
    const l2 = (await l2Token.functions.balanceOf(recipient))[0] as BigNumber;
    const bridge = (
      await l1Token.functions.balanceOf(
        messenger.contracts.l1.L1StandardBridge.address
      )
    )[0] as BigNumber;

    return [
      `    balance of L1 Sender    : ${l1.toBigInt() / Ether}`,
      `    balance of L1 Bridge    : ${bridge.toBigInt() / Ether}`,
      `    balance of L2 Recipient : ${l2.toBigInt() / Ether}`,
    ];
  };

  log("Initial Balance", ...(await reportBalance()), "\n");

  /**
   * Step 1
   */
  log("Approving of transferFrom to the L1StandardBridge...");

  let tx = await messenger.approveERC20(
    l1Token.address,
    l2Token.address,
    amount.toString()
  );
  await tx.wait();

  log(
    "done",
    `    tx: ${tx.hash}`,
    `        (More: ${opsdk.l1Explorer}/tx/${tx.hash})`,
    ...(await reportBalance()),
    "\n"
  );

  /**
   * Step 2
   */
  log("Deposit ERC20 to the L1StandardBridge...");

  tx = await messenger.depositERC20(
    l1Token.address,
    l2Token.address,
    amount.toString(),
    { recipient }
  );
  await tx.wait();

  log(
    "done",
    `    tx: ${tx.hash}`,
    `        (More: ${opsdk.l1Explorer}/tx/${tx.hash})`,
    ...(await reportBalance()),
    "\n"
  );

  /**
   * Step 3
   */
  log("Waiting for message to be relayed...");

  const start = new Date();
  await messenger.waitForMessageStatus(tx.hash, MessageStatus.RELAYED);

  const relayTx = await messenger.getMessageReceipt(tx.hash);
  log(
    `done (elapsed: ${(new Date().getTime() - start.getTime()) / 1000} sec)`,
    `    tx: ${relayTx.transactionReceipt.transactionHash}`,
    `        (More: ${opsdk.l2Explorer}/tx/${relayTx.transactionReceipt.transactionHash})`,
    ...(await reportBalance()),
    "\n"
  );
};

program
  .option("-r, --recipient <n>", "L2 Recipient address (default: sender)")
  .requiredOption("--l1-token <n>", "L1 Token Address")
  .requiredOption("--l2-token <n>", "L2 Token Address")
  .requiredOption("-a, --amount <n>", "Amount (unit: ether)")
  .showHelpAfterError();
program.parse();

main(program.opts<MainArgs>());
