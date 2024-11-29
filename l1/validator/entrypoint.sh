#!/bin/sh

# write the genesis block
if [ ! -d "/root/.ethereum/geth" ]; then
  geth init $GENESIS
fi

# write the node key for p2p
if [ -n "$NODE_KEY" ]; then
  echo -n "$NODE_KEY" > /root/.ethereum/geth/nodekey
fi

# enable block validation
if [ -n "$ETHERBASE" ]; then
  OPTS="$OPTS --mine --miner.etherbase $ETHERBASE --miner.gaslimit 30000000 --unlock $ETHERBASE"
fi

# enable fast finalization
if [ -n "$VOTE_KEY" ]; then
  OPTS="$OPTS --vote --vote-key-name $VOTE_KEY"
fi

# enable fake beacon
if [ "$ENABLE_FAKEBEACON" = "true" ]; then
    OPTS="$OPTS --fake-beacon --fake-beacon.addr 0.0.0.0"
fi

# To prevent blob freeze error of genesis block,
# avoid cancun start from the genesis block
# CANCUN_TIME=$(($(date +%s) + 30))
# OPTS="$OPTS --override.cancun $CANCUN_TIME --override.minforblobrequest 2300 --override.defaultextrareserve 200 --override.immutabilitythreshold 2150"

exec geth $OPTS $@
