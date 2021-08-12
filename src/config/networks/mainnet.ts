import EtherLogo from 'src/config/assets/token_eth.svg'
import { EnvironmentSettings, ETHEREUM_NETWORK, NetworkConfig } from 'src/config/networks/network.d'
import { ETHGASSTATION_API_KEY, SAFE_URL, TRANSACTION_SERVICE_URL, CLIENT_GATEWAY_URL } from 'src/utils/constants'

const baseConfig: EnvironmentSettings = {
  clientGatewayUrl: CLIENT_GATEWAY_URL || 'https://safe-client.mainnet.staging.gnosisdev.com/v1',
  txServiceUrl: TRANSACTION_SERVICE_URL || 'https://safe-transaction.mainnet.staging.gnosisdev.com/api/v1',
  safeUrl: SAFE_URL || 'https://gnosis-safe.io/app',
  gasPriceOracle: {
    url: `https://ethgasstation.info/json/ethgasAPI.json?api-key=${ETHGASSTATION_API_KEY}`,
    gasParameter: 'average',
    gweiFactor: '1e8',
  },
  safeAppsRpcServiceUrl: 'https://mainnet.infura.io:443/v3',
  rpcServiceUrl: 'https://mainnet.infura.io:443/v3',
  networkExplorerName: 'Etherscan',
  networkExplorerUrl: 'https://etherscan.io',
  networkExplorerApiUrl: 'https://api.etherscan.io/api',
}

const mainnet: NetworkConfig = {
  environment: {
    dev: {
      ...baseConfig,
      safeUrl: SAFE_URL || 'https://safe-team-mainnet.staging.gnosisdev.com/app/',
    },
    staging: {
      ...baseConfig,
      safeUrl: SAFE_URL || 'https://safe-team-mainnet.staging.gnosisdev.com/app/',
    },
    production: {
      ...baseConfig,
      clientGatewayUrl: CLIENT_GATEWAY_URL || 'https://safe-client.mainnet.gnosis.io/v1',
      txServiceUrl: TRANSACTION_SERVICE_URL || 'https://safe-transaction.mainnet.gnosis.io/api/v1',
    },
  },
  network: {
    id: ETHEREUM_NETWORK.MAINNET,
    backgroundColor: '#E8E7E6',
    textColor: '#001428',
    label: 'Mainnet',
    isTestNet: false,
    nativeCoin: {
      address: '0x0000000000000000000000000000000000000000',
      name: 'Ether',
      symbol: 'ETH',
      decimals: 18,
      logoUri: EtherLogo,
    },
  },
}

export default mainnet
