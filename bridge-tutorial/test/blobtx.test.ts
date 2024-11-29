import { resolve } from "path";
import * as cKzg from 'c-kzg'
import { setupKzg, http, createWalletClient, toBlobs, ToBlobsReturnType, parseGwei, stringToHex, defineChain, publicActions, parseUnits, formatUnits } from "viem";
import * as crypto from "crypto";
import { privateKeyToAccount } from 'viem/accounts'

// Define the byte size for random data
const BYTE_SIZE =131072 - 5120; // Adjust this value as needed
const INTERVAL = 1000; // 1000ms interval

const privateKey = process.env.PRIVATE_KEY!;

// Set up KZG interface
const trustedSetupPath = resolve(
  __dirname,
  'trusted-setups/trusted-setups.json',
)
const kzg = setupKzg(cKzg, trustedSetupPath);

// Initialize the Ethereum provider and wallet
const myCustomChain = defineChain({
  id: 12345, // Custom chain ID
  name: 'Oasys Local',
  network: 'oasys-local',
  nativeCurrency: {
      name: 'Oasys',
      symbol: 'OAS',
      decimals: 18,
  },
  rpcUrls: {
      default: { http: ['http://127.0.0.1:8545'] },
      public: { http: ['http://127.0.0.1:8545'] },
  },
  blockExplorers: {
      default: { name: 'OasysExplore', url: 'http://127.0.0.1:4000' },
  },
});
const account = privateKeyToAccount(`0x${privateKey}`)
const client = createWalletClient({
  account,
  chain: myCustomChain,
  transport: http('http://127.0.0.1:8545'),
}).extend(publicActions)

// Function to generate random byte data and convert it to blob using viem
function generateBlob(size: number): ToBlobsReturnType<'hex'> {
  const randomBytes = crypto.randomBytes(size)
  // console.log(`Generated random data: 0x${randomBytes.toString('hex')}`);
  return toBlobs({ data: `0x${randomBytes.toString('hex')}` })
}

async function estimateBlobGas(): Promise<bigint> {
  let estimatedBlobGasFee = BigInt(1)
  try {
    // Fetch the latest block to get the base fee
    const latestBlock = await client.getBlock({ blockTag: 'latest' });
    const baseFeePerGas = latestBlock.baseFeePerGas;

    if (!baseFeePerGas) {
      // console.warn('Base fee not available in the latest block');
      return estimatedBlobGasFee;
    }

    // Apply a multiplier or buffer to account for blob transaction gas demands
    const blobMultiplier = 1.2; // Adjust as needed based on network conditions
    estimatedBlobGasFee = parseUnits((Number(baseFeePerGas) * blobMultiplier).toString(), 0);

    console.log(`Estimated maxFeePerBlobGas (in Gwei): ${estimatedBlobGasFee.toString()}`);
  } catch (error) {
    console.error("Error estimating blob gas fee:", error);
  }
  return estimatedBlobGasFee;
}

// Function to create a blob transaction
async function createBlobTransaction(blobs: ToBlobsReturnType<'hex'>) {
  try {
    const hash = await client.sendTransaction({
      blobs,
      kzg,
      maxFeePerBlobGas: await estimateBlobGas(),
      // maxFeePerBlobGas: parseGwei('30'),
      to: '0x0000000000000000000000000000000000000000',
    });
    console.log("Transaction sent:", hash);
  } catch (error) {
    console.error("Failed to send transaction:", error);
  }
}

// Loop that sends blob transactions at a regular interval
const intervalId = setInterval(async () => {
  const blobData = generateBlob(BYTE_SIZE);
  await createBlobTransaction(blobData);
}, INTERVAL);

// Listen for SIGINT signal to stop the loop
process.on("SIGINT", () => {
  clearInterval(intervalId);
  console.log("\nStopped by user.");
  process.exit(0);
});
