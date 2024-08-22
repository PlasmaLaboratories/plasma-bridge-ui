# Integration Test Helpers
Spins up an environment, using Docker Compose, for testing the Bridge/Wallet. The compose file creates the following containers:
- Bitcoin Node (regtest)
- Bifrost Node (private local testnet)
- Envoy gRPC Web Proxy (for interacting with Bifrost gRPC from Web)
- Bridge Init Script (creates the necessary Asset Constructurs for tBTC)
- Bridge Consensus
- Bridge API

Once launched, Bifrost's gRPC-web endpoints can be reached at localhost:9094 and the Bridge API reached at localhost:5000.

## Usage
Launch:
1. `cd integration-test`
1. `docker compose rm -f -v`
1. `docker compose build`
1. `docker compose up`

Stop:
1. Ctrl+c to stop
1. `docker compose rm -f -v`
