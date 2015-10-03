###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import os
import io
import yaml
import glob
import time

from ssh_client import SSHClient
import common

exec_cmd = common.exec_cmd
err = common.err
check_file_exists = common.check_file_exists
log = common.log
parse = common.parse
commafy = common.commafy
N = common.N
E = common.E
R = common.R
RO = common.RO

CLOUD_DEPLOY_FILE = 'deploy.py'
BLADE_RESTART_TIMES = 3


class CloudDeploy(object):

    def __init__(self, dea, dha, fuel_ip, fuel_username, fuel_password,
                 dea_file, work_dir, no_health_check):
        self.dea = dea
        self.dha = dha
        self.fuel_ip = fuel_ip
        self.fuel_username = fuel_username
        self.fuel_password = fuel_password
        self.dea_file = dea_file
        self.work_dir = work_dir
        self.no_health_check = no_health_check
        self.file_dir = os.path.dirname(os.path.realpath(__file__))
        self.ssh = SSHClient(self.fuel_ip, self.fuel_username,
                             self.fuel_password)
        self.blade_node_file = '%s/blade_node.yaml' % self.file_dir
        self.node_ids = self.dha.get_node_ids()
        self.wanted_release = self.dea.get_property('wanted_release')
        self.blade_node_dict = {}
        self.macs_per_blade = {}

    def upload_cloud_deployment_files(self):
        with self.ssh as s:
            s.exec_cmd('rm -rf %s' % self.work_dir, False)
            s.exec_cmd('mkdir %s' % self.work_dir)
            s.scp_put(self.dea_file, self.work_dir)
            s.scp_put(self.blade_node_file, self.work_dir)
            s.scp_put('%s/common.py' % self.file_dir, self.work_dir)
            s.scp_put('%s/dea.py' % self.file_dir, self.work_dir)
            for f in glob.glob('%s/cloud/*' % self.file_dir):
                s.scp_put(f, self.work_dir)

    def power_off_nodes(self):
        for node_id in self.node_ids:
            self.dha.node_power_off(node_id)

    def power_on_nodes(self):
        for node_id in self.node_ids:
            self.dha.node_power_on(node_id)

    def set_boot_order(self, boot_order_list):
        for node_id in self.node_ids:
            self.dha.node_set_boot_order(node_id, boot_order_list[:])

    def get_mac_addresses(self):
        self.macs_per_blade = {}
        for node_id in self.node_ids:
            self.macs_per_blade[node_id] = self.dha.get_node_pxe_mac(node_id)

    def run_cloud_deploy(self, deploy_app):
        log('START CLOUD DEPLOYMENT')
        deploy_app = '%s/%s' % (self.work_dir, deploy_app)
        dea_file = '%s/%s' % (self.work_dir, os.path.basename(self.dea_file))
        blade_node_file = '%s/%s' % (
            self.work_dir, os.path.basename(self.blade_node_file))
        with self.ssh as s:
            status = s.run(
                'python %s %s %s %s' % (
                    deploy_app, ('-nh' if self.no_health_check else ''),
                    dea_file, blade_node_file))
        return status

    def check_supported_release(self):
        log('Check supported release: %s' % self.wanted_release)
        found = False
        release_list = parse(self.ssh.exec_cmd('fuel release -l'))
        for release in release_list:
            if release[R['name']] == self.wanted_release:
                found = True
                break
        if not found:
            err('This Fuel does not contain the following release: %s'
                % self.wanted_release)

    def check_previous_installation(self):
        log('Check previous installation')
        env_list = parse(self.ssh.exec_cmd('fuel env list'))
        if env_list:
            self.cleanup_fuel_environments(env_list)
            node_list = parse(self.ssh.exec_cmd('fuel node list'))
            if node_list:
                self.cleanup_fuel_nodes(node_list)

    def cleanup_fuel_environments(self, env_list):
        WAIT_LOOP = 60
        SLEEP_TIME = 10
        for env in env_list:
            log('Deleting environment %s' % env[E['id']])
            self.ssh.exec_cmd('fuel env --env %s --delete --force'
                              % env[E['id']])
        all_env_erased = False
        for i in range(WAIT_LOOP):
            env_list = parse(self.ssh.exec_cmd('fuel env list'))
            if env_list:
                time.sleep(SLEEP_TIME)
            else:
                all_env_erased = True
                break
        if not all_env_erased:
            err('Could not erase these environments %s'
                % [(env[E['id']], env[E['status']]) for env in env_list])

    def cleanup_fuel_nodes(self, node_list):
        for node in node_list:
            if node[N['status']] == 'discover':
                log('Deleting node %s' % node[N['id']])
                self.ssh.exec_cmd('fuel node --node-id %s --delete-from-db '
                                  '--force' % node[N['id']])
                self.ssh.exec_cmd('cobbler system remove --name node-%s'
                                  % node[N['id']], False)

    def check_prerequisites(self):
        log('Check prerequisites')
        with self.ssh:
            self.check_supported_release()
            self.check_previous_installation()

    def wait_for_discovered_blades(self):
        log('Wait for discovered blades')
        discovered_macs = []
        restart_times = BLADE_RESTART_TIMES

        for blade in self.node_ids:
            self.blade_node_dict[blade] = None

        with self.ssh:
            all_discovered = self.discovery_waiting_loop(discovered_macs)

        while not all_discovered and restart_times != 0:
            restart_times -= 1
            for blade in self.get_not_discovered_blades():
                self.dha.node_reset(blade)
            with self.ssh:
                all_discovered = self.discovery_waiting_loop(discovered_macs)

        if not all_discovered:
            err('Not all blades have been discovered: %s'
                % self.not_discovered_blades_summary())

        with io.open(self.blade_node_file, 'w') as stream:
            yaml.dump(self.blade_node_dict, stream, default_flow_style=False)

    def discovery_waiting_loop(self, discovered_macs):
        WAIT_LOOP = 360
        SLEEP_TIME = 10
        all_discovered = False
        for i in range(WAIT_LOOP):
            node_list = parse(self.ssh.exec_cmd('fuel node list'))
            if node_list:
                self.node_discovery(node_list, discovered_macs)
            if self.all_blades_discovered():
                all_discovered = True
                break
            else:
                time.sleep(SLEEP_TIME)
        return all_discovered

    def node_discovery(self, node_list, discovered_macs):
        for node in node_list:
            if (node[N['status']] == 'discover' and
                node[N['online']] == 'True' and
                node[N['mac']] not in discovered_macs):
                discovered_macs.append(node[N['mac']])
                blade = self.find_mac_in_dict(node[N['mac']])
                if blade:
                    log('Blade %s discovered as Node %s with MAC %s'
                        % (blade, node[N['id']], node[N['mac']]))
                    self.blade_node_dict[blade] = node[N['id']]

    def find_mac_in_dict(self, mac):
        for blade, mac_list in self.macs_per_blade.iteritems():
            if mac in mac_list:
                return blade

    def all_blades_discovered(self):
        for blade, node_id in self.blade_node_dict.iteritems():
            if not node_id:
                return False
        return True

    def not_discovered_blades_summary(self):
        summary = ''
        for blade, node_id in self.blade_node_dict.iteritems():
            if not node_id:
                summary += '\n[blade %s]' % blade
        return summary

    def get_not_discovered_blades(self):
        not_discovered_blades = []
        for blade, node_id in self.blade_node_dict.iteritems():
            if not node_id:
                not_discovered_blades.append(blade)
        return not_discovered_blades

    def set_boot_order_nodes(self):
        self.power_off_nodes()
        self.set_boot_order(['pxe', 'disk'])
        self.power_on_nodes()

    def deploy(self):

        self.set_boot_order_nodes()

        self.check_prerequisites()

        self.get_mac_addresses()

        self.wait_for_discovered_blades()

        self.upload_cloud_deployment_files()

        return self.run_cloud_deploy(CLOUD_DEPLOY_FILE)
