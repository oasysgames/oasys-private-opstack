import { program } from "commander";
import { Contract } from "ethers";
import { MessageStatus } from "@eth-optimism/sdk";
import { ERC721ABI, log } from "./lib";
import { ERC721BridgeAdapter } from "./lib/erc721-bridge-adapter";
import * as opsdk from "./lib/sdk";

// Setup the OP Stack SDK
const privateKey = process.env.PRIVATE_KEY!;
const { l1Signer, l2Signer } = opsdk.getSigners({ privateKey });
const messenger = opsdk.getCrossChainMessenger({
  l1Signer,
  l2Signer,
  bridgeAdapter: {
    adapter: ERC721BridgeAdapter,
    l1Bridge: opsdk.l1Contracts.L1ERC721BridgeProxy,
    l2Bridge: "0x4200000000000000000000000000000000000014",
  },
});

// Main
type MainArgs = {
  l1Token: string;
  l2Token: string;
  tokenId: string;
  recipient?: string;
};

const main = async (args: MainArgs) => {
  const recipient = args.recipient ?? l1Signer.address;

  const l1Token = new Contract(args.l1Token, [ERC721ABI], l1Signer.provider);
  const l2Token = new Contract(args.l2Token, [ERC721ABI], l2Signer.provider);

  const reportBalance = async (): Promise<string[]> => {
    const l1 = (await l1Token.functions.ownerOf(args.tokenId))[0];
    let l2 = "";
    try {
      l2 = (await l2Token.functions.ownerOf(args.tokenId))[0];
    } catch (e) {
      // @ts-ignore
      const reason = e.reason as undefined | string;
      if (!reason || !/^ERC721/.test(reason)) {
        throw e;
      }

      l2 = "";
    }
    return [`    L1 Owner : ${l1}`, `    L2 Owner : ${l2}`];
  };

  log("Initial Balance", ...(await reportBalance()), "\n");

  /**
   * Step 1
   */
  log("Transfer and Burn ERC721 to the L2ERC721Bridge...");

  let tx = await messenger.withdrawERC20(
    l1Token.address,
    l2Token.address,
    args.tokenId,
    { recipient }
  );
  await tx.wait();

  log(
    "done",
    `    tx: ${tx.hash}`,
    `        (More: ${opsdk.l2Explorer}/tx/${tx.hash})`,
    ...(await reportBalance()),
    "\n"
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
    "done",
    `    elapsed: ${(new Date().getTime() - start.getTime()) / 1000} sec\n\n`
  );

  /**
   * Step 3
   */
  log("Sending a prove message to the CrossChainMessenger...");

  tx = await messenger.proveMessage(withdrawTxHash);
  await tx.wait();

  log(
    "done",
    `    tx: ${tx.hash}`,
    `        (More: ${opsdk.l1Explorer}/tx/${tx.hash})`,
    ...(await reportBalance()),
    "\n"
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
    "done",
    `    elapsed: ${(new Date().getTime() - start.getTime()) / 1000} sec\n\n`
  );

  /**
   * Step 5
   */
  log("Sending a finalizing message to the OptimismPortal...");

  tx = await messenger.finalizeMessage(withdrawTxHash);
  await tx.wait();

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

  log(
    "done",
    `    elapsed: ${(new Date().getTime() - start.getTime()) / 1000} sec`,
    ...(await reportBalance()),
    "\n"
  );
};

program
  .option("-r, --recipient <n>", "L2 Recipient address (default: sender)")
  .requiredOption("--l1-token <n>", "L1 Token Address")
  .requiredOption("--l2-token <n>", "L2 Token Address")
  .requiredOption("--token-id <n>", "Token ID")
  .showHelpAfterError();
program.parse();

main(program.opts<MainArgs>());
