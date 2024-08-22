#!/bin/bash

# This script is responsible for initializing an empty wallet and then funding that wallet with some LVLs and initializing the necessary bridge assets on chain


alias brambl-cli="cs launch -r https://s01.oss.sonatype.org/content/repositories/releases co.topl:brambl-cli_2.13:2.0.0-beta5 -- "
export BTC_USER=bitcoin
export BTC_PASSWORD=password
export TOPL_WALLET_PASSWORD=password
export TOPL_WALLET_DB=/app/wallet/topl-wallet.db
export TOPL_WALLET_JSON=/app/wallet/topl-wallet.json
export TOPL_WALLET_MNEMONIC=/app/wallet/topl-mnemonic.txt

rm -f $TOPL_WALLET_DB $TOPL_WALLET_JSON $TOPL_WALLET_MNEMONIC

openssl ecparam -name secp256k1 -genkey -noout -out /app/wallet/consensusPrivateKey.pem
openssl ec -in /app/wallet/consensusPrivateKey.pem -pubout -out /app/wallet/consensusPublicKey.pem
openssl ecparam -name secp256k1 -genkey -noout -out /app/wallet/clientPrivateKey.pem
openssl ec -in /app/wallet/clientPrivateKey.pem -pubout -out /app/wallet/clientPublicKey.pem

bitcoin-cli -regtest -named -rpcconnect=bitcoin -rpcuser=bitcoin -rpcpassword=password createwallet wallet_name=testwallet
export BTC_ADDRESS=`bitcoin-cli -rpcconnect=bitcoin -rpcuser=$BTC_USER -rpcpassword=$BTC_PASSWORD -rpcwallet=testwallet -regtest getnewaddress`
echo BTC Address: $BTC_ADDRESS
bitcoin-cli -rpcconnect=bitcoin -rpcuser=$BTC_USER -rpcpassword=$BTC_PASSWORD -regtest generatetoaddress 101 $BTC_ADDRESS

brambl-cli wallet init --network private --password $TOPL_WALLET_PASSWORD --newwalletdb $TOPL_WALLET_DB --mnemonicfile $TOPL_WALLET_MNEMONIC --output $TOPL_WALLET_JSON
export ADDRESS=$(brambl-cli wallet current-address --walletdb $TOPL_WALLET_DB)

cd /app

echo "Genesis UTxOs"
brambl-cli genus-query utxo-by-address --from-fellowship nofellowship --from-template genesis --host bifrost --port 9084 --secure false --walletdb $TOPL_WALLET_DB
brambl-cli simple-transaction create --from-fellowship nofellowship --from-template genesis --from-interaction 1 --change-fellowship nofellowship --change-template genesis --change-interaction 1  -t $ADDRESS -w $TOPL_WALLET_PASSWORD -o genesisTx.pbuf -n private -a 10000 -h bifrost --port 9084 --keyfile $TOPL_WALLET_JSON --walletdb $TOPL_WALLET_DB --fee 10 --transfer-token lvl
brambl-cli tx prove -i genesisTx.pbuf --walletdb $TOPL_WALLET_DB --keyfile $TOPL_WALLET_JSON -w $TOPL_WALLET_PASSWORD -o genesisTxProved.pbuf
export GROUP_UTXO=$(brambl-cli tx broadcast -i genesisTxProved.pbuf -h bifrost --port 9084 --secure false)
echo "GROUP_UTXO: $GROUP_UTXO"
until brambl-cli genus-query utxo-by-address --host bifrost --port 9084 --secure false --walletdb $TOPL_WALLET_DB; do sleep 5; done
echo "label: ToplBTCGroup" > groupPolicy.yaml
echo "registrationUtxo: $GROUP_UTXO#0" >> groupPolicy.yaml
brambl-cli simple-minting create --from-fellowship self --from-template default -h bifrost --port 9084 --secure false -n private --keyfile $TOPL_WALLET_JSON -w $TOPL_WALLET_PASSWORD -o groupMintingtx.pbuf -i groupPolicy.yaml  --mint-amount 1 --fee 10 --walletdb $TOPL_WALLET_DB --mint-token group
brambl-cli tx prove -i groupMintingtx.pbuf --walletdb $TOPL_WALLET_DB --keyfile $TOPL_WALLET_JSON -w $TOPL_WALLET_PASSWORD -o groupMintingtxProved.pbuf
export SERIES_UTXO=$(brambl-cli tx broadcast -i groupMintingtxProved.pbuf -h bifrost --port 9084 --secure false)
echo "SERIES_UTXO: $SERIES_UTXO"
until brambl-cli genus-query utxo-by-address --host bifrost --port 9084 --secure false --walletdb $TOPL_WALLET_DB; do sleep 5; done
echo "label: ToplBTCSeries" > seriesPolicy.yaml
echo "registrationUtxo: $SERIES_UTXO#0" >> seriesPolicy.yaml
echo "fungibility: group-and-series" >> seriesPolicy.yaml
echo "quantityDescriptor: liquid" >> seriesPolicy.yaml
brambl-cli simple-minting create --from-fellowship self --from-template default  -h bifrost --port 9084 --secure false -n private --keyfile $TOPL_WALLET_JSON -w $TOPL_WALLET_PASSWORD -o seriesMintingTx.pbuf -i seriesPolicy.yaml  --mint-amount 1 --fee 10 --walletdb $TOPL_WALLET_DB --mint-token series
brambl-cli tx prove -i seriesMintingTx.pbuf --walletdb $TOPL_WALLET_DB --keyfile $TOPL_WALLET_JSON -w $TOPL_WALLET_PASSWORD -o seriesMintingTxProved.pbuf
export ASSET_UTXO=$(brambl-cli tx broadcast -i seriesMintingTxProved.pbuf -h bifrost --port 9084 --secure false)
echo "ASSET_UTXO: $ASSET_UTXO"
until brambl-cli genus-query utxo-by-address --host bifrost --port 9084 --secure false --walletdb $TOPL_WALLET_DB; do sleep 5; done
brambl-cli wallet balance --from-fellowship self --from-template default --walletdb $TOPL_WALLET_DB --host bifrost --port 9084 --secure false

export GROUP_ID=$(brambl-cli genus-query utxo-by-address -h bifrost --port 9084 --secure false --walletdb $TOPL_WALLET_DB | /bin/bash /extract_group_series_id.sh "Group Constructor")
echo "GROUP_ID: $GROUP_ID"
echo $GROUP_ID > /app/wallet/groupId.txt

export SERIES_ID=$(brambl-cli genus-query utxo-by-address -h bifrost --port 9084 --secure false --walletdb $TOPL_WALLET_DB | /bin/bash /extract_group_series_id.sh "Series Constructor")
echo "SERIES_ID: $SERIES_ID"
echo $SERIES_ID > /app/wallet/seriesId.txt
