###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################

import time
import os
import glob
from ssh_client import SSHClient
from dha_adapters.libvirt_adapter import LibvirtAdapter

from common import (
    log,
    err,
    delete,
)

TRANSPLANT_FUEL_SETTINGS = 'transplant_fuel_settings.py'
BOOTSTRAP_ADMIN = 'bootstrap_admin_node'
FUEL_CLIENT_CONFIG = '/etc/fuel/client/config.yaml'
PLUGINS_DIR = '~/plugins'
LOCAL_PLUGIN_FOLDER = '/opt/opnfv'
IGNORABLE_FUEL_ERRORS = ['does not update installed package',
                         'Couldn\'t resolve host']


class InstallFuelMaster(object):

    def __init__(self, dea_file, dha_file, fuel_ip, fuel_username,
                 fuel_password, fuel_node_id, iso_file, work_dir,
                 fuel_plugins_dir, no_plugins):
        self.dea_file = dea_file
        self.dha = LibvirtAdapter(dha_file)
        self.fuel_ip = fuel_ip
        self.fuel_username = fuel_username
        self.fuel_password = fuel_password
        self.fuel_node_id = fuel_node_id
        self.iso_file = iso_file
        self.iso_dir = os.path.dirname(self.iso_file)
        self.work_dir = work_dir
        self.fuel_plugins_dir = fuel_plugins_dir
        self.no_plugins = no_plugins
        self.file_dir = os.path.dirname(os.path.realpath(__file__))
        self.ssh = SSHClient(self.fuel_ip, self.fuel_username,
                             self.fuel_password)

    def install(self):
        log('Start Fuel Installation')

        self.dha.node_power_off(self.fuel_node_id)

        if os.environ.get('LIBVIRT_DEFAULT_URI'):
            log('Upload ISO to pool')
            self.iso_file = self.dha.upload_iso(self.iso_file)
        else:
            log('Zero the MBR')
            self.dha.node_zero_mbr(self.fuel_node_id)

        self.dha.node_set_boot_order(self.fuel_node_id, ['disk', 'iso'])

        try:
            self.proceed_with_installation()
        except Exception as e:
            self.post_install_cleanup()
            err(e)

    def proceed_with_installation(self):
        log('Eject ISO')
        self.dha.node_eject_iso(self.fuel_node_id)

        log('Insert ISO %s' % self.iso_file)
        self.dha.node_insert_iso(self.fuel_node_id, self.iso_file)

        self.dha.node_power_on(self.fuel_node_id)

        log('Waiting for Fuel master to accept SSH')
        self.wait_for_node_up()

        log('Wait until Fuel menu is up')
        fuel_menu_pid = self.wait_until_fuel_menu_up()

        log('Inject our own astute.yaml and fuel_bootstrap_cli.yaml settings')
        self.inject_own_astute_and_bootstrap_yaml()

        log('Let the Fuel deployment continue')
        log('Found FUEL menu as PID %s, now killing it' % fuel_menu_pid)
        self.ssh_exec_cmd('kill %s' % fuel_menu_pid, False)

        log('Wait until installation is complete')
        self.wait_until_installation_completed()

        log('Waiting for one minute for Fuel to stabilize')
        time.sleep(60)

        self.delete_deprecated_fuel_client_config()

        if not self.no_plugins:

            self.collect_plugin_files()

            self.install_plugins()

        self.post_install_cleanup()

        log('Fuel Master installed successfully !')

    def collect_plugin_files(self):
        with self.ssh as s:
            s.exec_cmd('mkdir %s' % PLUGINS_DIR)
            if self.fuel_plugins_dir:
                for f in glob.glob('%s/*.rpm' % self.fuel_plugins_dir):
                    s.scp_put(f, PLUGINS_DIR)

    def install_plugins(self):
        log('Installing Fuel Plugins')
        plugin_files = []
        with self.ssh as s:
            for plugin_location in [PLUGINS_DIR, LOCAL_PLUGIN_FOLDER]:
                s.exec_cmd('mkdir -p %s' % plugin_location)
                r = s.exec_cmd('find %s -type f -name \'*.rpm\''
                               % plugin_location)
                plugin_files.extend(r.splitlines())
            for f in plugin_files:
                log('Found plugin %s, installing ...' % f)
                r, e = s.exec_cmd('fuel plugins --install %s' % f, False)
                printout = r + e if e else r
                if e and all([err not in printout
                              for err in IGNORABLE_FUEL_ERRORS]):
                    raise Exception('Installation of Fuel Plugin %s '
                                    'failed: %s' % (f, e))

    def wait_for_node_up(self):
        WAIT_LOOP = 240
        SLEEP_TIME = 10
        success = False
        for i in range(WAIT_LOOP):
            try:
                self.ssh.open()
                success = True
                break
            except Exception:
                log('Trying to SSH into Fuel VM %s ... sleeping %s seconds'
                    % (self.fuel_ip, SLEEP_TIME))
                time.sleep(SLEEP_TIME)
            finally:
                self.ssh.close()

        if not success:
            raise Exception('Could not SSH into Fuel VM %s' % self.fuel_ip)

    def wait_until_fuel_menu_up(self):
        WAIT_LOOP = 60
        SLEEP_TIME = 10
        CMD = 'pgrep -f fuelmenu'
        fuel_menu_pid = None
        with self.ssh:
            for i in range(WAIT_LOOP):
                ret = self.ssh.exec_cmd(CMD)
                fuel_menu_pid = ret.strip()
                if not fuel_menu_pid:
                    time.sleep(SLEEP_TIME)
                else:
                    break
        if not fuel_menu_pid:
            raise Exception('Could not find the Fuel Menu Process ID')
        return fuel_menu_pid

    def ssh_exec_cmd(self, cmd, check=True):
        with self.ssh:
            ret = self.ssh.exec_cmd(cmd, check=check)
        return ret

    def inject_own_astute_and_bootstrap_yaml(self):
        with self.ssh as s:
            s.exec_cmd('rm -rf %s' % self.work_dir, False)
            s.exec_cmd('mkdir %s' % self.work_dir)
            s.scp_put(self.dea_file, self.work_dir)
            s.scp_put('%s/common.py' % self.file_dir, self.work_dir)
            s.scp_put('%s/dea.py' % self.file_dir, self.work_dir)
            s.scp_put('%s/transplant_fuel_settings.py'
                      % self.file_dir, self.work_dir)
            log('Modifying Fuel astute')
            s.run('python %s/%s %s/%s'
                  % (self.work_dir, TRANSPLANT_FUEL_SETTINGS,
                     self.work_dir, os.path.basename(self.dea_file)))

    def wait_until_installation_completed(self):
        WAIT_LOOP = 360
        SLEEP_TIME = 10
        CMD = 'pgrep -f %s' % BOOTSTRAP_ADMIN

        install_completed = False
        with self.ssh:
            for i in range(WAIT_LOOP):
                ret = self.ssh.exec_cmd(CMD)
                if not ret:
                    install_completed = True
                    break
                else:
                    time.sleep(SLEEP_TIME)

        if not install_completed:
            raise Exception('Fuel installation did not complete')

    def post_install_cleanup(self):
        log('Eject ISO file %s' % self.iso_file)
        self.dha.node_eject_iso(self.fuel_node_id)
        delete(self.iso_dir)

    def delete_deprecated_fuel_client_config(self):
        with self.ssh as s:
            response, error = s.exec_cmd('fuel -v', False)
        if (error and
            'DEPRECATION WARNING' in error and FUEL_CLIENT_CONFIG in error):
            log('Delete deprecated fuel client config %s' % FUEL_CLIENT_CONFIG)
            with self.ssh as s:
                s.exec_cmd('rm %s' % FUEL_CLIENT_CONFIG, False)
