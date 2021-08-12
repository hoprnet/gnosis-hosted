import os.path
import tempfile
from io import StringIO
from unittest import mock
from unittest.mock import MagicMock

from django.core.management import call_command
from django.test import TestCase

from django_celery_beat.models import PeriodicTask

from gnosis.eth.ethereum_client import EthereumClient, EthereumNetwork

from ..models import ProxyFactory, SafeMasterCopy
from .factories import MultisigTransactionFactory, SafeContractFactory


class TestCommands(TestCase):
    @mock.patch.object(EthereumClient, 'get_network', autospec=True)
    def _test_setup_service(self, ethereum_network: EthereumNetwork, ethereum_client_get_network_mock: MagicMock):
        command = 'setup_service'
        ethereum_client_get_network_mock.return_value = ethereum_network
        buf = StringIO()
        self.assertEqual(SafeMasterCopy.objects.count(), 0)
        self.assertEqual(ProxyFactory.objects.count(), 0)
        self.assertEqual(PeriodicTask.objects.count(), 0)

        call_command(command, stdout=buf)
        self.assertIn(f'Setting up {ethereum_network.name} safe addresses', buf.getvalue())
        self.assertIn(f'Setting up {ethereum_network.name} proxy factory addresses', buf.getvalue())
        self.assertIn('Created Periodic Task', buf.getvalue())
        self.assertNotIn('was already created', buf.getvalue())
        self.assertGreater(SafeMasterCopy.objects.count(), 0)
        self.assertGreater(ProxyFactory.objects.count(), 0)
        self.assertGreater(PeriodicTask.objects.count(), 0)

        # Check last master copy was created
        last_master_copy_address = '0x6851D6fDFAfD08c0295C392436245E5bc78B0185'
        last_master_copy = SafeMasterCopy.objects.get(address=last_master_copy_address)
        self.assertGreater(last_master_copy.initial_block_number, 0)
        self.assertGreater(last_master_copy.tx_block_number, 0)

        # Check last proxy factory was created
        last_proxy_factory_address = '0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B'
        last_proxy_factory = ProxyFactory.objects.get(address=last_proxy_factory_address)
        self.assertGreater(last_proxy_factory.initial_block_number, 0)
        self.assertGreater(last_proxy_factory.tx_block_number, 0)

        buf = StringIO()
        call_command(command, stdout=buf)
        self.assertIn(f'Setting up {ethereum_network.name} safe addresses', buf.getvalue())
        self.assertIn(f'Setting up {ethereum_network.name} proxy factory addresses', buf.getvalue())
        self.assertNotIn('Created Periodic Task', buf.getvalue())
        self.assertIn('was already created', buf.getvalue())

    def test_index_erc20(self):
        command = 'index_erc20'
        buf = StringIO()
        call_command(command, stdout=buf)
        self.assertIn('No addresses to process', buf.getvalue())

        buf = StringIO()
        call_command(command, '--block-process-limit=10', stdout=buf)
        self.assertIn('Setting block-process-limit to 10', buf.getvalue())

        buf = StringIO()
        call_command(command, '--block-process-limit=10', '--block-process-limit-max=15', stdout=buf)
        self.assertIn('Setting block-process-limit to 10', buf.getvalue())
        self.assertIn('Setting block-process-limit-max to 15', buf.getvalue())

        safe_contract = SafeContractFactory()
        buf = StringIO()
        call_command(command, stdout=buf)
        self.assertIn(f'Start indexing ERC20 addresses {[safe_contract.address]}', buf.getvalue())
        self.assertIn(f'End indexing ERC20 addresses {[safe_contract.address]}', buf.getvalue())

        safe_contract_2 = SafeContractFactory()
        buf = StringIO()
        call_command(command, f'--addresses={safe_contract_2.address}', stdout=buf)
        self.assertIn(f'Start indexing ERC20 addresses {[safe_contract_2.address]}', buf.getvalue())
        self.assertIn(f'End indexing ERC20 addresses {[safe_contract_2.address]}', buf.getvalue())

    def test_setup_service_mainnet(self):
        self._test_setup_service(EthereumNetwork.MAINNET)

        # Check last master copy was created
        last_master_copy_address = '0x6851D6fDFAfD08c0295C392436245E5bc78B0185'
        last_master_copy_initial_block = 10329734
        last_master_copy = SafeMasterCopy.objects.get(address=last_master_copy_address)
        self.assertEqual(last_master_copy.initial_block_number, last_master_copy_initial_block)
        self.assertEqual(last_master_copy.tx_block_number, last_master_copy_initial_block)

        # Check last proxy factory was created
        last_proxy_factory_address = '0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B'
        last_proxy_factory_initial_block = 9084508
        last_proxy_factory = ProxyFactory.objects.get(address=last_proxy_factory_address)
        self.assertEqual(last_proxy_factory.initial_block_number, last_proxy_factory_initial_block)
        self.assertEqual(last_proxy_factory.tx_block_number, last_proxy_factory_initial_block)

        self.assertEqual(SafeMasterCopy.objects.count(), 8)
        self.assertEqual(SafeMasterCopy.objects.l2().count(), 1)
        self.assertEqual(ProxyFactory.objects.count(), 4)

    def test_setup_service_rinkeby(self):
        self._test_setup_service(EthereumNetwork.RINKEBY)

    def test_setup_service_goerli(self):
        self._test_setup_service(EthereumNetwork.GOERLI)

    def test_setup_service_kovan(self):
        self._test_setup_service(EthereumNetwork.KOVAN)

    @mock.patch.object(EthereumClient, 'get_network', autospec=True)
    def test_setup_service_not_valid_network(self, ethereum_client_get_network_mock: MagicMock):
        command = 'setup_service'
        for return_value in (EthereumNetwork.ROPSTEN, EthereumNetwork.UNKNOWN):
            ethereum_client_get_network_mock.return_value = return_value
            buf = StringIO()
            call_command(command, stdout=buf)
            self.assertIn('Cannot detect a valid ethereum-network', buf.getvalue())

    def test_export_multisig_tx_data(self):
        with tempfile.TemporaryDirectory() as tmpdirname:
            command = 'export_multisig_tx_data'
            arguments = '--file-name=' + os.path.join(tmpdirname, 'result.csv')
            buf = StringIO()
            call_command(command, arguments, stdout=buf)
            self.assertIn('Start exporting of 0', buf.getvalue())

            MultisigTransactionFactory(origin='something')
            MultisigTransactionFactory(origin='another-something', ethereum_tx=None)  # Will not be exported
            MultisigTransactionFactory(origin=None)  # Will not be exported
            buf = StringIO()
            call_command(command, arguments, stdout=buf)
            self.assertIn('Start exporting of 1', buf.getvalue())
