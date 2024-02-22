import * as ethers from "ethers";
import * as readline from 'readline';
import * as opsdk from "./lib/sdk";

const privateKey = process.env.PRIVATE_KEY!;
const { l1Provider, l2Provider } = opsdk.getProviders();
const { l2Signer } = opsdk.getSigners({ privateKey, l1Provider, l2Provider });
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});
const Amount = "1"

// Function to wait for a specified number of milliseconds
const delay = (ms: number) => new Promise(res => setTimeout(res, ms));

async function main() {
  // Ask for the number of times to send the transaction
  rl.question('Enter the number of times to send 1 wei: ', async (times) => {
    const numberOfTimes = parseInt(times);
    if (isNaN(numberOfTimes)) {
      console.error("Invalid number entered");
      rl.close();
      return;
    }

    await task(numberOfTimes);

    rl.close();
  })
}

async function task(count: number) {
  // Generate a random wallet and use its address as the recipient
  const randomWallet = ethers.Wallet.createRandom();
  const recipientAddress = randomWallet.address;

  await sendTransaction(recipientAddress, Amount);

  // Wait for 1 second
  await delay(1000);

  // If the count is greater than 1, run the task again
  if (count > 1) {
    task(count - 1);
  }
}

async function sendTransaction(to : string, value : string) {
  const tx = {
    to: to,
    value: ethers.utils.parseEther(value) // Amount to send in ETH
  };
  try {
    // Send transaction
    const transaction = await l2Signer.sendTransaction(tx);
    console.log("Transaction hash:", transaction.hash);
    // Wait for transaction confirmation
    await transaction.wait();
    console.log("Transaction confirmed");
  } catch (error) {
    console.error("Error sending transaction:", error);
  }
}

main().catch((error) => {
  console.error("Error in main execution:", error);
});
