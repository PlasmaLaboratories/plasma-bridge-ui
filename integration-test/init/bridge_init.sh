#!/bin/bash

# This script is responsible for initializing an empty wallet and then funding that wallet with some LVLs and initializing the necessary bridge assets on chain


alias brambl-cli="cs launch -r https://s01.oss.sonatype.org/content/repositories/releases org.plasmalabs:plasma-cli_2.13:0.1.0 -- "
export BTC_USER=bitcoin
export BTC_PASSWORD=password
export PLASMA_WALLET_PASSWORD=password
export PLASMA_WALLET_DB=/app/wallet/plasma-wallet.db
export PLASMA_WALLET_JSON=/app/wallet/plasma-wallet.json
export PLASMA_WALLET_MNEMONIC=/app/wallet/plasma-mnemonic.txt
export PLASMA_NODE_HOST=plasmanode

rm -f $PLASMA_WALLET_DB $PLASMA_WALLET_JSON $PLASMA_WALLET_MNEMONIC

openssl ecparam -name secp256k1 -genkey -noout -out /app/wallet/consensusPrivateKey.pem
openssl ec -in /app/wallet/consensusPrivateKey.pem -pubout -out /app/wallet/consensusPublicKey.pem
openssl ecparam -name secp256k1 -genkey -noout -out /app/wallet/clientPrivateKey.pem
openssl ec -in /app/wallet/clientPrivateKey.pem -pubout -out /app/wallet/clientPublicKey.pem

bitcoin-cli -regtest -named -rpcconnect=bitcoin -rpcuser=bitcoin -rpcpassword=password createwallet wallet_name=testwallet
export BTC_ADDRESS=`bitcoin-cli -rpcconnect=bitcoin -rpcuser=$BTC_USER -rpcpassword=$BTC_PASSWORD -rpcwallet=testwallet -regtest getnewaddress`
echo BTC Address: $BTC_ADDRESS
bitcoin-cli -rpcconnect=bitcoin -rpcuser=$BTC_USER -rpcpassword=$BTC_PASSWORD -regtest generatetoaddress 101 $BTC_ADDRESS

brambl-cli wallet init --network private --password $PLASMA_WALLET_PASSWORD --newwalletdb $PLASMA_WALLET_DB --mnemonicfile $PLASMA_WALLET_MNEMONIC --output $PLASMA_WALLET_JSON
export ADDRESS=$(brambl-cli wallet current-address --walletdb $PLASMA_WALLET_DB)

cd /app

echo "Genesis UTxOs"
brambl-cli indexer-query utxo-by-address --from-fellowship nofellowship --from-template genesis --host $PLASMA_NODE_HOST --port 9084 --secure false --walletdb $PLASMA_WALLET_DB
brambl-cli simple-transaction create --from-fellowship nofellowship --from-template genesis --from-interaction 1 --change-fellowship nofellowship --change-template genesis --change-interaction 1  -t $ADDRESS -w $PLASMA_WALLET_PASSWORD -o genesisTx.pbuf -n private -a 10000 -h $PLASMA_NODE_HOST --port 9084 --keyfile $PLASMA_WALLET_JSON --walletdb $PLASMA_WALLET_DB --fee 10 --transfer-token lvl
brambl-cli tx prove -i genesisTx.pbuf --walletdb $PLASMA_WALLET_DB --keyfile $PLASMA_WALLET_JSON -w $PLASMA_WALLET_PASSWORD -o genesisTxProved.pbuf
export GROUP_UTXO=$(brambl-cli tx broadcast -i genesisTxProved.pbuf -h $PLASMA_NODE_HOST --port 9084 --secure false)
echo "GROUP_UTXO: $GROUP_UTXO"
until brambl-cli indexer-query utxo-by-address --host $PLASMA_NODE_HOST --port 9084 --secure false --walletdb $PLASMA_WALLET_DB; do sleep 5; done
echo "label: PlasmaBTCGroup" > groupPolicy.yaml
echo "registrationUtxo: $GROUP_UTXO#0" >> groupPolicy.yaml
brambl-cli simple-minting create --from-fellowship self --from-template default -h $PLASMA_NODE_HOST --port 9084 --secure false -n private --keyfile $PLASMA_WALLET_JSON -w $PLASMA_WALLET_PASSWORD -o groupMintingtx.pbuf -i groupPolicy.yaml  --mint-amount 1 --fee 10 --walletdb $PLASMA_WALLET_DB --mint-token group
brambl-cli tx prove -i groupMintingtx.pbuf --walletdb $PLASMA_WALLET_DB --keyfile $PLASMA_WALLET_JSON -w $PLASMA_WALLET_PASSWORD -o groupMintingtxProved.pbuf
export SERIES_UTXO=$(brambl-cli tx broadcast -i groupMintingtxProved.pbuf -h $PLASMA_NODE_HOST --port 9084 --secure false)
echo "SERIES_UTXO: $SERIES_UTXO"
until brambl-cli indexer-query utxo-by-address --host $PLASMA_NODE_HOST --port 9084 --secure false --walletdb $PLASMA_WALLET_DB; do sleep 5; done
echo "label: PlasmaBTCSeries" > seriesPolicy.yaml
echo "registrationUtxo: $SERIES_UTXO#0" >> seriesPolicy.yaml
echo "fungibility: group-and-series" >> seriesPolicy.yaml
echo "quantityDescriptor: liquid" >> seriesPolicy.yaml
brambl-cli simple-minting create --from-fellowship self --from-template default  -h $PLASMA_NODE_HOST --port 9084 --secure false -n private --keyfile $PLASMA_WALLET_JSON -w $PLASMA_WALLET_PASSWORD -o seriesMintingTx.pbuf -i seriesPolicy.yaml  --mint-amount 1 --fee 10 --walletdb $PLASMA_WALLET_DB --mint-token series
brambl-cli tx prove -i seriesMintingTx.pbuf --walletdb $PLASMA_WALLET_DB --keyfile $PLASMA_WALLET_JSON -w $PLASMA_WALLET_PASSWORD -o seriesMintingTxProved.pbuf
export ASSET_UTXO=$(brambl-cli tx broadcast -i seriesMintingTxProved.pbuf -h $PLASMA_NODE_HOST --port 9084 --secure false)
echo "ASSET_UTXO: $ASSET_UTXO"
until brambl-cli indexer-query utxo-by-address --host $PLASMA_NODE_HOST --port 9084 --secure false --walletdb $PLASMA_WALLET_DB; do sleep 5; done
brambl-cli wallet balance --from-fellowship self --from-template default --walletdb $PLASMA_WALLET_DB --host $PLASMA_NODE_HOST --port 9084 --secure false

export GROUP_ID=$(brambl-cli indexer-query utxo-by-address -h $PLASMA_NODE_HOST --port 9084 --secure false --walletdb $PLASMA_WALLET_DB | /bin/bash /extract_group_series_id.sh "Group Constructor")
echo "GROUP_ID: $GROUP_ID"
echo $GROUP_ID > /app/wallet/groupId.txt

export SERIES_ID=$(brambl-cli indexer-query utxo-by-address -h $PLASMA_NODE_HOST --port 9084 --secure false --walletdb $PLASMA_WALLET_DB | /bin/bash /extract_group_series_id.sh "Series Constructor")
echo "SERIES_ID: $SERIES_ID"
echo $SERIES_ID > /app/wallet/seriesId.txt
