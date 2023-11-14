# Private OP Stack

## Setup

### Clone repositories

Clone repositories to any location you prefer.

```shell
# mkdir ~/your/dev/dir && cd ~/your/dev/dir

git clone --recursive https://github.com/oasysgames/oasys-validator.git 

git clone https://github.com/ethereum-optimism/optimism.git op-monorepo

git clone https://github.com/ethereum-optimism/op-geth.git
```

The `oasys-validator` repository checks out a release tag for a testnet that allows for free contract deployment.

```shell
cd oasys-validator

# check the latest release tag
git tag | grep testnet

git checkout xxx-testnet
```

Installation of dependencies is required in the `op-monorepo` repository.  
See the official document. See also the [official document](https://stack.optimism.io/docs/build/getting-started/#build-the-optimism-monorepo).
```shell
cd op-monorepo

pnpm install && pnpm build
```

### Create `.env` file

Copy the sample.
```shell
cp .env.sample .env
```

Add the absolute path of the repository cloned earlier.
```dotenv
L1_GETH_REPO=<oasys-validator>
OP_MONO_REPO=<op-monorepo>
OP_GETH_REPO=<op-geth>
```

### Build OP Stack images

```shell
# first, build the base image
docker-compose build op-builder

docker-compose build
```

### Pull other images

```shell
docker-compose pull
```

### Run L1 Services

Run main services of L1.
```shell
docker-compose up -d l1-web l1-bootnode l1-rpc l1-validator1
```

L1 block creation starts automatically, so execute `l1-validator1` staking within the 1st epoch (40 blocks). Open the l1-web ([http://127.0.0.1:8080/](http://127.0.0.1:8080/)) and click `1. Join` and `2. Stake` button. 
> l1-validator2 and l1-validator3 are optional.

![Join & Stake](./.README/join-and-stake.jpg)

Run the explorer ([http://127.0.0.1:4000/](http://127.0.0.1:4000/)).
```shell
docker-compose up -d postgres && sleep 20 && docker-compose up -d l1-blockscout
```

### Generate `getting-started.json` and `.envrc`

Generate a `getting-started.json` and `.envrc` file within the op-monorepo repository. These files will be used for the subsequent contract deployment and genesis.json generation.

```shell
# getting-started.json
docker-compose run --rm foundry 'bash /misc/foundry/deploy-config.sh > /op-monorepo/packages/contracts-bedrock/deploy-config/getting-started.json'

# .envrc
docker-compose run --rm foundry 'bash /misc/foundry/envrc.sh > /op-monorepo/.envrc'
```

### Deploy OP Stack contracts to L1

```shell
cd op-monorepo/

# load .envrc
direnv allow

cd packages/contracts-bedrock/ 
```

#### Deploy L1 contracts

```shell
forge script scripts/Deploy.s.sol:Deploy \
  --private-key $GS_ADMIN_PRIVATE_KEY \
  --rpc-url $L1_RPC_URL \
  --broadcast

# output on success
> Total Paid: 0.083734833 ETH (27911611 gas * avg 3 gwei)
> 
> Transactions saved to: /op-monorepo/packages/contracts-bedrock/broadcast/Deploy.s.sol/12345/run-latest.json
> 
> Sensitive values saved to: /op-monorepo/packages/contracts-bedrock/cache/Deploy.s.sol/12345/run-latest.json
```

#### Generate contract artifacts

```shell
forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --rpc-url $L1_RPC_URL

# output on success
>  Syncing deployment SystemConfigProxy: contract Proxy
>  Deploy Tx not found for SystemOwnerSafe skipping deployment artifact generation
>  Synced temp deploy files, deleting /op-monorepo/packages/contracts-bedrock/deployments/getting-started/.deploy
```

#### Set L2OutputOracleProxy address to `.env`

Get the address of the `L2OutputOracleProxy` contract.
```shell
jq -r .address deployments/getting-started/L2OutputOracleProxy.json
```

And set it as the `OP_L2OO_ADDR` in the `.env` file.
```dotenv
## address of the `L2OutputOracle` contract on L1
OP_L2OO_ADDR=<here>
```

### Generate `genesis.json` and `rollup.json`

Generate a `genesis.json` and `rollup.json` for the OP Stack.

```shell
docker-compose run --rm --no-deps op-node genesis l2 \
  --deploy-config /op-monorepo/packages/contracts-bedrock/deploy-config/getting-started.json \
  --deployment-dir /op-monorepo/packages/contracts-bedrock/deployments/getting-started/ \
  --outfile.l2 /data/genesis.json \
  --outfile.rollup /data/rollup.json \
  --l1-rpc http://l1-rpc:8545/

# check the generated files
ls -l data/op-node/{genesis.json,rollup.json}
```

### Generate op-geth genesis block

```shell
docker-compose run --rm op-geth init /op-node/genesis.json

# output on success
INFO [11-09|16:06:49.261] Successfully wrote genesis state         database=lightchaindata                      hash=1498e7..1a0467
```

### Run OP Stack Services

Run main services of OP Stack.
```shell
docker-compose up -d op-geth op-node op-batcher op-proposer
```

Run the explorer ([http://127.0.0.1:4001/](http://127.0.0.1:4001/)). If op-geth and op-node are running correctly, blocks should be being created every 5 seconds.
```shell
docker-compose up -d op-blockscout
```

## FAQs

### How to get the OAS？

The L1 OAS can be received from the Faucet by opening l1-web ([http://127.0.0.1:8080/](http://127.0.0.1:8080/)) and using `Get L1 OAS`. The OPStack OAS needs to be bridged from L1.

### Blocks are not synchronizing between `l1-rpc` and `l1-validator`

The IP address of the container changes with start/stop, but geth may be caching the old IP address. Try deleting the cache with the following command.

```shell
docker-compose stop l1-rpc l1-validator1

rm -rf data/l1-*/geth/nodes 

docker-compose up -d l1-rpc l1-validator1
```

### How to reset L1 and OP Stack?

Stop all services.
```shell
docker-compose down --remove-orphans --volumes
```

Delete container data.
```shell
rm -rf data
```

Delete data within op-monorepo.
```shell
rm -rf packages/contracts-bedrock/deploy-config/getting-started.json\
       packages/contracts-bedrock/deployments/getting-started
```

Then repeat the steps after [Run L1 Services](#run-l1-services).
