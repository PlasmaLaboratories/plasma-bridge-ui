# Integration Test Helpers
Spins up an environment, using Docker Compose, for testing the Bridge/Wallet. The compose file creates the following containers:
- Bitcoin Node (regtest)
- Plasma Node (private local testnet)
- Envoy gRPC Web Proxy (for interacting with gRPC from Web)
- Bridge Init Script (creates the necessary Asset Constructurs for tBTC)
- Bridge Consensus
- Bridge API

Once launched, gRPC-web endpoints can be reached at localhost:9094 and the Bridge API reached at localhost:5000.

## Usage
Launch:
1. `cd integration-test`
1. `docker compose rm -f -v`
1. `docker compose build`
1. `docker compose up`

Fund BTC address:
1. Open new terminal
1. `cd integration-test`
1. `./fund-escrow.sh <btc address here>` (replace with the address presented in the UI)

Stop:
1. Ctrl+c to stop
1. `docker compose rm -f -v`
