#!/bin/sh

# write the genesis block
if [ ! -d "/root/.ethereum/geth" ]; then
  geth init $GENESIS
fi

# write the node key for p2p
if [ -n "$NODEKEY" ]; then
  echo -n "$NODEKEY" > /root/.ethereum/geth/nodekey
fi

# sync only mode if the `ETHERBASE` is not set
if [ -n "$ETHERBASE" ]; then
  OPTS="$OPTS --mine --miner.etherbase $ETHERBASE --miner.gaslimit 30000000"
  OPTS="$OPTS --keystore $KEYSTORE --unlock $ETHERBASE --password /dev/null --allow-insecure-unlock"
  OPTS="$OPTS --vote=true --blswallet=$BLS_WALLET/wallet --blspassword=$BLS_WALLET/password.txt --vote-journal-path=$VOTEJOURNAL"
fi

exec geth \
  --keystore $KEYSTORE --bootnodes $BOOTNODES \
  --syncmode full --gcmode archive --networkid $NETWORK_ID \
  --http --http.addr 0.0.0.0 --http.vhosts '*' --http.corsdomain '*' --http.api net,eth,web3,txpool,debug,admin \
  --ws --ws.addr 0.0.0.0 --ws.origins '*' --ws.api net,eth,web3,txpool,debug,admin \
  $OPTS $@
