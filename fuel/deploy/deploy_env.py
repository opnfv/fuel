import os
import io
import yaml
import glob

from ssh_client import SSHClient
import common

exec_cmd = common.exec_cmd
err = common.err
check_file_exists = common.check_file_exists
log = common.log

CLOUD_DEPLOY_FILE = 'deploy.py'


class CloudDeploy(object):

    def __init__(self, dha, fuel_ip, fuel_username, fuel_password, dea_file,
                 work_dir):
        self.dha = dha
        self.fuel_ip = fuel_ip
        self.fuel_username = fuel_username
        self.fuel_password = fuel_password
        self.dea_file = dea_file
        self.work_dir = work_dir
        self.file_dir = os.path.dirname(os.path.realpath(__file__))
        self.ssh = SSHClient(self.fuel_ip, self.fuel_username,
                             self.fuel_password)
        self.macs_file = '%s/macs.yaml' % self.file_dir
        self.node_ids = self.dha.get_node_ids()

    def upload_cloud_deployment_files(self):
        dest ='~/%s/' % self.work_dir

        with self.ssh as s:
            s.exec_cmd('rm -rf %s' % self.work_dir, check=False)
            s.exec_cmd('mkdir ~/%s' % self.work_dir)
            s.scp_put(self.dea_file, dest)
            s.scp_put(self.macs_file, dest)
            s.scp_put('%s/common.py' % self.file_dir, dest)
            s.scp_put('%s/dea.py' % self.file_dir, dest)
            for f in glob.glob('%s/cloud/*' % self.file_dir):
                s.scp_put(f, dest)

    def power_off_nodes(self):
        for node_id in self.node_ids:
            self.dha.node_power_off(node_id)

    def power_on_nodes(self):
        for node_id in self.node_ids:
            self.dha.node_power_on(node_id)

    def set_boot_order(self, boot_order_list):
        for node_id in self.node_ids:
            self.dha.node_set_boot_order(node_id, boot_order_list)

    def get_mac_addresses(self):
        macs_per_node = {}
        for node_id in self.node_ids:
            macs_per_node[node_id] = self.dha.get_node_pxe_mac(node_id)
        with io.open(self.macs_file, 'w') as stream:
            yaml.dump(macs_per_node, stream, default_flow_style=False)

    def run_cloud_deploy(self, deploy_app):
        log('START CLOUD DEPLOYMENT')
        deploy_app = '%s/%s' % (self.work_dir, deploy_app)
        dea_file = '%s/%s' % (self.work_dir, os.path.basename(self.dea_file))
        macs_file = '%s/%s' % (self.work_dir, os.path.basename(self.macs_file))
        with self.ssh:
            self.ssh.run('python %s %s %s' % (deploy_app, dea_file, macs_file))

    def deploy(self):

        self.power_off_nodes()

        self.set_boot_order(['pxe', 'disk'])

        self.power_on_nodes()

        self.get_mac_addresses()

        check_file_exists(self.macs_file)

        self.upload_cloud_deployment_files()

        self.run_cloud_deploy(CLOUD_DEPLOY_FILE)
