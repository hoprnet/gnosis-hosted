# Self hosted Gnosis Safe

This repository provides a setup to run [Gnosis Safe](https://gnosis-safe.io/)
on a custom host with minimal dependencies, mainly Docker.

The configuration consists of:

- a Docker Compose configuration for `local` testing and `production` deployment
  - the configuration includes a SSL reverse proxy which sits in front of all relevant HTTP endpoints
- service configuration files for `local` testing and `production` deployment for all services in `configs/`
  - gnosis-safe-react: the web client
  - gnosis-safe-client-gateway: proxy between the web client and the transaction service
  - gnosis-safe-transaction-service: watches on-chain events and indexes relevant transaction information 
  - gnosis-safe-config-service: used by the client gateway for runtime configuration

The repository vendors all dependencies in `vendor/`:

```
gnosis-safe-client-gateway@v3.3.0:
	name:	gnosis-safe-client-gateway
	dir:	vendor/github.com/gnosis/safe-client-gateway
	repo:	https://github.com/gnosis/safe-client-gateway
	ref:	v3.3.0
	commit:	a05494a8f1d6e33eff12bfe9deb88a3efa70c41b

gnosis-safe-config-service@v2.0.1:
	name:	gnosis-safe-config-service
	dir:	vendor/github.com/gnosis/safe-config-service
	repo:	https://github.com/gnosis/safe-config-service
	ref:	v2.0.1
	commit:	44836efc91a8f1a75e023d57a73b463d81824d6a

gnosis-safe-react@tb/configurable-mainnet-endpoints-based-on-dev:
	name:	gnosis-safe-react
	dir:	vendor/github.com/hoprnet/safe-react
	repo:	https://github.com/hoprnet/safe-react
	ref:	tb/configurable-mainnet-endpoints-based-on-dev
	commit:	a7e43151ca9f149e4c16627c73d6bdf5f17f1942

gnosis-safe-transaction-service@v3.1.25:
	name:	gnosis-safe-transaction-service
	dir:	vendor/github.com/gnosis/safe-transaction-service
	repo:	https://github.com/gnosis/safe-transaction-service
	ref:	v3.1.25
	commit:	90e87a2b5a894469cf09dec1507a954e266dae05
```

# Background

In short, Gnosis Safe relies in a series of [centralized services](https://docs.gnosis.io/safe/docs/services_relay/)
to provide the great UX it currently has. Unfortunately, as any centralized provider, it can go down and make everyone
unhappy that their DAO can not buy the latest stoner cat or whatever the kids are doing nowadays.

So instead of tweeting about Gnosis Safe being done (we are [guilty](https://twitter.com/paulkhls/status/1420798041934663681?s=20) of have doing so), we put together this stack that quickly spins your own Gnosis Safe for you
to use.

# Instructions

These steps are meant as guidelines and might be 1-to-1 what you need. Instead
use this repository as a guide and adapt it where needed to suite your
requirements.

- Clone this repository
- Search for `PLACEHOLDER_CHANGE_ME` in the `configs/` directory and replace
  each occurence with a proper value. Most service configurations are common
  between `local` and `production` versions and therefore kept in a separate
  `.common` file
- (production-only) Push configuration files onto server such that they can
  be used by the Docker daemon at container runtime: `make prepare_production`
- Build and start containers:
```
GNOSIS_ENVIRONMENT=production \
GNOSIS_SAFE_DOMAIN=gnosis-safe.abcd.ef \
GNOSIS_SAFE_SUPPORT_EMAIL=tech@gnosis-safe.abcd.ef \
make start
```
  Use `GNOSIS_ENVIRONMENT=local` for local testing
- At this point all services should be started and keep running. If services
	are crashing, check their logs to identify issues.
- Create config-service admin user: `docker exec -ti gnosis_config-service-web_1 python src/manage.py createsuperuser`
- Create transaction-service admin user: `docker exec -ti gnosis_transaction-service-web_1 python manage.py createsuperuser`
- Setup DNS A-records (or AAAA if you are using IPv6) to point to the server:
  - "${GNOSIS_SAFE_DOMAIN}"
  - "config-service-${GNOSIS_SAFE_DOMAIN}"
  - "transaction-service-${GNOSIS_SAFE_DOMAIN}"
- Configure client-gateway by adding chain record in config-service:
  - go to `https://config-service.${GNOSIS_SAFE_DOMAIN}/admin`, replace the placeholder with your domain
  - log in with previously created admin
	- navigate to `chains` and click `Add Chain`
	- here are values as an example, however you most likely need to adapt them
	  - chain id: `1`
		- relavance: `100`
		- chain name: `mainnet`
		- rpc uri: VALID_ETH_ENDPOINT
		- safe apps rpc uri: VALID_ETH_ENDPOINT
		- block explorer uri address template: `https://etherscan.io/address/{{address}}`
		- block explorer uri tx hash template: `https://etherscan.io/address/{{txHash}}`
		- currency name: `ether`
		- currency symbol: `ETH`
		- currency decimals: `18`
		- currency logo url: `https://cryptologos.cc/logos/ethereum-eth-logo.png`
		- transaction service uri: `http://172.16.238.100:8888`
		- theme text color: `#ffffff`
		- theme background color: `#000000`
		- gas price oracle uri: `https://etherchain.org/api/gasPriceOracle`
		- gas price oracle parameter: `average`
		- gwei multiplier factor: `1.0`
		- recommended master copy version: `1.1.1`
	- save
- Configure client-gateway webhook in transaction-service:
  - go to `https://transaction-service.${GNOSIS_SAFE_DOMAIN}/admin`, replace the placeholder with your domain
  - log in with previously created admin
	- navigate to `web hooks` and click `Add Web Hook`
	- here are values as an example, however you most likely need to adapt them
	  - url: `http://172.16.238.110:3666/v1/hook/update/WEBHOOK_TOKEN_PLACEHOLDER`, use the token from the client gateway configuration
- wait until indexer has reached current network top
  - check `https://transaction-service-${GNOSIS_SAFE_DOMAIN}/admin/history/ethereumblock/`

Once the indexer has caught up with the network top, you can start using your
custom Gnosis Safe installation at `https://${GNOSIS_SAFE_DOMAIN}`.
