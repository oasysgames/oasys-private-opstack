# OP Stack Bridge Tutorial

## Setup

Install dependencies.
```shell
yarn
```

Set the private key of the wallet to the `PRIVATE_KEY` environment variable
```shell
direnv edit .
```

Setup the [OP Stack SDK](https://community.optimism.io/docs/sdk/), but to use on a private chain, take a few [extra steps](https://stack.optimism.io/docs/build/sdk/#not-natively-supported-chains) is required. By using this script, you can skip those steps and use the SDK.
```shell
docker-compose run --rm -v $PWD:/bridge-tutorial foundry 'bash /misc/foundry/sdk.sh > /bridge-tutorial/src/lib/sdk.js'
```

## Bridge OAS

[Official Tutorial](https://github.com/ethereum-optimism/optimism-tutorial/tree/cc4f9fd8514a61871165b47097af919ea2a40be7/cross-dom-bridge-eth)

### Deposit (L1 -> L2)

Bridge to yourself.
```shell
npx ts-node src/deposit-oas.ts --amount 1
```

Bridge to specified recipient.
```shell
npx ts-node src/deposit-oas.ts --amount 1 --recipient 0x...
```

### Withdraw (L2 -> L1)

Bridge to yourself.
```shell
npx ts-node src/withdraw-oas.ts --amount 1
```

Bridge to specified recipient.
```shell
npx ts-node src/withdraw-oas.ts --amount 1 --recipient 0x...
```

## Bridge ERC20

[Official Tutorial](https://github.com/ethereum-optimism/optimism-tutorial/tree/cc4f9fd8514a61871165b47097af919ea2a40be7/cross-dom-bridge-erc20)

### Deploy and Mint of ERC20

```shell
# Go to op-monorepo directory
cd /path/to/op-monorepo

# Minter's private key
export MINTER_KEY=0x...

# Address of the token recipient
export RECIPIENT=0x...

# Address of the L1StandardERC20Factory
export L1_ERC20_FACTORY=0x5200000000000000000000000000000000000004

# Address of the OptimismMintableERC20Factory
export L2_ERC20_FACTORY=0x4200000000000000000000000000000000000012

# Token name
export ERC20_NAME="MYCOIN($(date '+%H%M%S'))"

# Log directory
export ERC20_LOGDIR="$(mktemp -d)"

# Deploy L1 token using factory
cast send --private-key "$MINTER_KEY" --rpc-url "$L1_RPC_URL" \
  "$L1_ERC20_FACTORY" \
  "createStandardERC20(string,string)" \
  "$ERC20_NAME" "$ERC20_NAME" > $ERC20_LOGDIR/l1token.txt

# Get address of the L1 token
export L1_ERC20="0x$(grep topics $ERC20_LOGDIR/l1token.txt | cut -c 5- | jq -rM '.[-1].topics[-1][26:]')"

# Deploy L2 token using factory
cast send --private-key "$MINTER_KEY" --rpc-url "$L2_RPC_URL" \
  "$L2_ERC20_FACTORY" \
  "createOptimismMintableERC20(address,string,string)" \
  "$L1_ERC20" "$ERC20_NAME" "$ERC20_NAME" > $ERC20_LOGDIR/l2token.txt

# Get address of the L2 token
export L2_ERC20="0x$(grep topics $ERC20_LOGDIR/l2token.txt | cut -c 5- | jq -rM '.[-1].topics[1][26:]')"

# Mint the L1 token (amount is 1e18)
cast send --private-key "$MINTER_KEY" --rpc-url "$L1_RPC_URL" \
  "$L1_ERC20" \
  "mint(address,uint256)" \
  "$RECIPIENT" 1000000000000000000
```

### Deposit (L1 -> L2)

Bridge to yourself.
```shell
# Set the deployed token addresses ($L1_ERC20 and $L2_ERC20)
npx ts-node src/deposit-erc20.ts \
  --l1-token 0x... \
  --l2-token 0x... \
  --amount 1
```

Bridge to specified recipient.
```shell
npx ts-node src/deposit-erc20.ts \
  --l1-token 0x... \
  --l2-token 0x... \
  --amount 1 \
  --recipient 0x...
```

### Withdraw (L2 -> L1)

Bridge to yourself.
```shell
npx ts-node src/withdraw-erc20.ts \
  --l1-token 0x... \
  --l2-token 0x... \
  --amount 1
```

Bridge to specified recipient.
```shell
npx ts-node src/withdraw-erc20.ts \
  --l1-token 0x... \
  --l2-token 0x... \
  --amount 1 \
  --recipient 0x...
```

## Bridge ERC721

### Deploy and Mint of ERC721

```shell
# Go to op-monorepo directory
cd /path/to/op-monorepo

# Minter's private key
export MINTER_KEY=0x...

# Address of the token recipient
export RECIPIENT=0x...

# Address of the L1StandardERC721Factory
export L1_ERC721_FACTORY=0x5200000000000000000000000000000000000005

# Address of the OptimismMintableERC721Factory
export L2_ERC721_FACTORY=0x4200000000000000000000000000000000000017

# Token name
export ERC721_NAME="MYHERO($(date '+%H%M%S'))"

# Log directory
export ERC721_LOGDIR="$(mktemp -d)"

# Deploy L1 token using factory
cast send --private-key "$MINTER_KEY" --rpc-url "$L1_RPC_URL" \
  "$L1_ERC721_FACTORY" \
  "createStandardERC721(string,string,string)" \
  "$ERC721_NAME" "$ERC721_NAME" "https://example.com/" > $ERC721_LOGDIR/l1token.txt

# Get address of the L1 token
export L1_ERC721="0x$(grep topics $ERC721_LOGDIR/l1token.txt | cut -c 5- | jq -rM '.[-1].topics[-1][26:]')"

# Deploy L2 token using factory
cast send --private-key "$MINTER_KEY" --rpc-url "$L2_RPC_URL" \
  "$L2_ERC721_FACTORY" \
  "createOptimismMintableERC721(address,string,string)" \
  "$L1_ERC721" "$ERC721_NAME" "$ERC721_NAME" > $ERC721_LOGDIR/l2token.txt

# Get address of the L2 token
export L2_ERC721="0x$(grep topics $ERC721_LOGDIR/l2token.txt | cut -c 5- | jq -rM '.[-1].topics[1][26:]')"

# Mint the L1 token (token id is 1)
cast send --private-key "$MINTER_KEY" --rpc-url "$L1_RPC_URL" \
  "$L1_ERC721" \
  "mint(address,uint256)" \
  "$RECIPIENT" 1
```

### Deposit (L1 -> L2)

Bridge to yourself.
```shell
# Set the deployed token addresses ($L1_ERC721 and $L2_ERC721)
npx ts-node src/deposit-erc721.ts \
  --l1-token 0x... \
  --l2-token 0x... \
  --token-id 1
```

Bridge to specified recipient.
```shell
npx ts-node src/deposit-erc721.ts \
  --l1-token 0x... \
  --l2-token 0x... \
  --token-id 1 \
  --recipient 0x...
```

### Withdraw (L2 -> L1)

Bridge to yourself.
```shell
npx ts-node src/withdraw-erc721.ts \
  --l1-token 0x... \
  --l2-token 0x... \
  --token-id 1
```

Bridge to specified recipient.
```shell
npx ts-node src/withdraw-erc721.ts \
  --l1-token 0x... \
  --l2-token 0x... \
  --token-id 1 \
  --recipient 0x...
```
