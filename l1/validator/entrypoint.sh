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

exec geth $OPTS $@
