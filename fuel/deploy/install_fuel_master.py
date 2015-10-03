import common
import time
import os
from ssh_client import SSHClient
from dha_adapters.libvirt_adapter import LibvirtAdapter

log = common.log
err = common.err
clean = common.clean

TRANSPLANT_FUEL_SETTINGS = 'transplant_fuel_settings.py'
BOOTSTRAP_ADMIN = '/usr/local/sbin/bootstrap_admin_node'

class InstallFuelMaster(object):

    def __init__(self, dea_file, dha_file, fuel_ip, fuel_username, fuel_password,
                 fuel_node_id, iso_file, work_dir):
        self.dea_file = dea_file
        self.dha = LibvirtAdapter(dha_file)
        self.fuel_ip = fuel_ip
        self.fuel_username = fuel_username
        self.fuel_password = fuel_password
        self.fuel_node_id = fuel_node_id
        self.iso_file = iso_file
        self.work_dir = work_dir
        self.file_dir = os.path.dirname(os.path.realpath(__file__))
        self.ssh = SSHClient(self.fuel_ip, self.fuel_username,
                             self.fuel_password)

    def install(self):
        log('Start Fuel Installation')

        self.dha.node_power_off(self.fuel_node_id)

        self.zero_mbr_set_boot_order()

        self.proceed_with_installation()

    def custom_install(self):
        log('Start Custom Fuel Installation')

        self.dha.node_power_off(self.fuel_node_id)

        log('Zero the MBR')
        self.dha.node_zero_mbr(self.fuel_node_id)

        self.dha.node_set_boot_order(self.fuel_node_id, ['disk', 'iso'])

        self.proceed_with_installation()

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

        log('Inject our own astute.yaml settings')
        self.inject_own_astute_yaml()

        log('Let the Fuel deployment continue')
        log('Found FUEL menu as PID %s, now killing it' % fuel_menu_pid)
        self.ssh_exec_cmd('kill %s' % fuel_menu_pid)

        log('Wait until installation complete')
        self.wait_until_installation_completed()

        log('Waiting for one minute for Fuel to stabilize')
        time.sleep(60)

        log('Eject ISO')
        self.dha.node_eject_iso(self.fuel_node_id)

        log('Fuel Master installed successfully !')

    def zero_mbr_set_boot_order(self):
        if self.dha.node_can_zero_mbr(self.fuel_node_id):
            log('Fuel Node %s capable of zeroing MBR so doing that...'
                % self.fuel_node_id)
            self.dha.node_zero_mbr(self.fuel_node_id)
            self.dha.node_set_boot_order(self.fuel_node_id, ['disk', 'iso'])
        elif self.dha.node_can_set_boot_order_live(self.fuel_node_id):
            log('Node %s can change ISO boot order live' % self.fuel_node_id)
            self.dha.node_set_boot_order(self.fuel_node_id, ['iso', 'disk'])
        else:
            err('No way to install Fuel node')

    def wait_for_node_up(self):
        WAIT_LOOP = 60
        SLEEP_TIME = 10
        success = False
        for i in range(WAIT_LOOP):
            try:
                self.ssh.open()
                success = True
                break
            except Exception as e:
                log('EXCEPTION [%s] received when SSH-ing into Fuel VM %s ... '
                    'sleeping %s seconds' % (e, self.fuel_ip, SLEEP_TIME))
                time.sleep(SLEEP_TIME)
            finally:
                self.ssh.close()

        if not success:
           err('Could not SSH into Fuel VM %s' % self.fuel_ip)

    def wait_until_fuel_menu_up(self):
        WAIT_LOOP = 60
        SLEEP_TIME = 10
        CMD = 'ps -ef'
        SEARCH = 'fuelmenu'
        fuel_menu_pid = None
        with self.ssh:
            for i in range(WAIT_LOOP):
                ret = self.ssh.exec_cmd(CMD)
                fuel_menu_pid = self.get_fuel_menu_pid(ret, SEARCH)
                if not fuel_menu_pid:
                    time.sleep(SLEEP_TIME)
                else:
                    break
        if not fuel_menu_pid:
            err('Could not find the Fuel Menu Process ID')
        return fuel_menu_pid

    def get_fuel_menu_pid(self, printout, search):
        fuel_menu_pid = None
        for line in printout.splitlines():
            if search in line:
                fuel_menu_pid = clean(line)[1]
                break
        return fuel_menu_pid

    def ssh_exec_cmd(self, cmd):
        with self.ssh:
            ret = self.ssh.exec_cmd(cmd)
        return ret

    def inject_own_astute_yaml(self):
        dest ='~/%s/' % self.work_dir

        with self.ssh as s:
            s.exec_cmd('rm -rf %s' % self.work_dir, check=False)
            s.exec_cmd('mkdir ~/%s' % self.work_dir)
            s.scp_put(self.dea_file, dest)
            s.scp_put('%s/common.py' % self.file_dir, dest)
            s.scp_put('%s/dea.py' % self.file_dir, dest)
            s.scp_put('%s/transplant_fuel_settings.py' % self.file_dir, dest)
            log('Modifying Fuel astute')
            s.run('python ~/%s/%s ~/%s/%s'
                  % (self.work_dir, TRANSPLANT_FUEL_SETTINGS,
                     self.work_dir, os.path.basename(self.dea_file)))

    def wait_until_installation_completed(self):
        WAIT_LOOP = 180
        SLEEP_TIME = 10
        CMD = 'ps -ef | grep %s | grep -v grep' % BOOTSTRAP_ADMIN

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
            err('Fuel installation did not complete')
