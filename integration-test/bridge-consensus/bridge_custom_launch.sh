#!/bin/bash

export SERIES_ID=$(cat /app/wallet/seriesId.txt)
export GROUP_ID=$(cat /app/wallet/groupId.txt)
touch /app/wallet/bridge.db
/opt/docker/bin/plasma-btc-bridge-consensus --plasma-host plasmanode --btc-url http://bitcoin --zmq-host bitcoin --plasma-wallet-seed-file /app/wallet/plasma-wallet.json --plasma-wallet-db /app/wallet/plasma-wallet.db --btc-peg-in-seed-file /app/btc-wallet/peg-in-wallet.json --btc-wallet-seed-file /app/btc-wallet/btc-wallet.json --abtc-group-id $GROUP_ID --abtc-series-id $SERIES_ID --config-file /application.conf --db-file /app/wallet/bridge.db
