import sys
import os
import shutil
import io
import re
import netaddr

from dea import DeploymentEnvironmentAdapter
from dha import DeploymentHardwareAdapter
from install_fuel_master import InstallFuelMaster
from deploy_env import CloudDeploy
import common

log = common.log
exec_cmd = common.exec_cmd
err = common.err
check_file_exists = common.check_file_exists
check_if_root = common.check_if_root

FUEL_VM = 'fuel'
TMP_DIR = '%s/fueltmp' % os.getenv('HOME')
PATCH_DIR = 'fuel_patch'
WORK_DIR = 'deploy'

class cd:
    def __init__(self, new_path):
        self.new_path = os.path.expanduser(new_path)

    def __enter__(self):
        self.saved_path = os.getcwd()
        os.chdir(self.new_path)

    def __exit__(self, etype, value, traceback):
        os.chdir(self.saved_path)


class AutoDeploy(object):

    def __init__(self, without_fuel, iso_file, dea_file, dha_file):
        self.without_fuel = without_fuel
        self.iso_file = iso_file
        self.dea_file = dea_file
        self.dha_file = dha_file
        self.dea = DeploymentEnvironmentAdapter(dea_file)
        self.dha = DeploymentHardwareAdapter(dha_file)
        self.fuel_conf = {}
        self.fuel_node_id = self.dha.get_fuel_node_id()
        self.fuel_custom = self.dha.use_fuel_custom_install()
        self.fuel_username, self.fuel_password = self.dha.get_fuel_access()

    def setup_dir(self, dir):
        self.cleanup_dir(dir)
        os.makedirs(dir)

    def cleanup_dir(self, dir):
        if os.path.isdir(dir):
            shutil.rmtree(dir)

    def power_off_blades(self):
        node_ids = self.dha.get_all_node_ids()
        node_ids = list(set(node_ids) - set([self.fuel_node_id]))
        for node_id in node_ids:
            self.dha.node_power_off(node_id)

    def modify_ip(self, ip_addr, index, val):
        ip_str = str(netaddr.IPAddress(ip_addr))
        decimal_list = map(int, ip_str.split('.'))
        decimal_list[index] = val
        return '.'.join(map(str, decimal_list))

    def collect_fuel_info(self):
        self.fuel_conf['ip'] = self.dea.get_fuel_ip()
        self.fuel_conf['gw'] = self.dea.get_fuel_gateway()
        self.fuel_conf['dns1'] = self.dea.get_fuel_dns()
        self.fuel_conf['netmask'] = self.dea.get_fuel_netmask()
        self.fuel_conf['hostname'] = self.dea.get_fuel_hostname()
        self.fuel_conf['showmenu'] = 'yes'

    def install_fuel_master(self):
        if self.without_fuel:
            log('Not Installing Fuel Master')
            return
        log('Install Fuel Master')
        new_iso = '%s/deploy-%s' % (TMP_DIR, os.path.basename(self.iso_file))
        self.patch_iso(new_iso)
        self.iso_file = new_iso
        self.install_iso()

    def install_iso(self):
        fuel = InstallFuelMaster(self.dea_file, self.dha_file,
                                 self.fuel_conf['ip'], self.fuel_username,
                                 self.fuel_password, self.fuel_node_id,
                                 self.iso_file, WORK_DIR)
        if self.fuel_custom:
            log('Custom Fuel install')
            fuel.custom_install()
        else:
            log('Ordinary Fuel install')
            fuel.install()

    def patch_iso(self, new_iso):
        tmp_orig_dir = '%s/origiso' % TMP_DIR
        tmp_new_dir = '%s/newiso' % TMP_DIR
        self.copy(tmp_orig_dir, tmp_new_dir)
        self.patch(tmp_new_dir, new_iso)

    def copy(self, tmp_orig_dir, tmp_new_dir):
        log('Copying...')
        self.setup_dir(tmp_orig_dir)
        self.setup_dir(tmp_new_dir)
        exec_cmd('fuseiso %s %s' % (self.iso_file, tmp_orig_dir))
        with cd(tmp_orig_dir):
            exec_cmd('find . | cpio -pd %s' % tmp_new_dir)
        with cd(tmp_new_dir):
            exec_cmd('fusermount -u %s' % tmp_orig_dir)
        shutil.rmtree(tmp_orig_dir)
        exec_cmd('chmod -R 755 %s' % tmp_new_dir)

    def patch(self, tmp_new_dir, new_iso):
        log('Patching...')
        patch_dir = '%s/%s' % (os.getcwd(), PATCH_DIR)
        ks_path = '%s/ks.cfg.patch' % patch_dir

        with cd(tmp_new_dir):
            exec_cmd('cat %s | patch -p0' % ks_path)
            shutil.rmtree('.rr_moved')
            isolinux = 'isolinux/isolinux.cfg'
            log('isolinux.cfg before: %s'
                % exec_cmd('grep netmask %s' % isolinux))
            self.update_fuel_isolinux(isolinux)
            log('isolinux.cfg after: %s'
                % exec_cmd('grep netmask %s' % isolinux))

            iso_linux_bin = 'isolinux/isolinux.bin'
            exec_cmd('mkisofs -quiet -r -J -R -b %s '
                     '-no-emul-boot -boot-load-size 4 '
                     '-boot-info-table -hide-rr-moved '
                     '-x "lost+found:" -o %s .'
                     % (iso_linux_bin, new_iso))

    def update_fuel_isolinux(self, file):
        with io.open(file) as f:
            data = f.read()
        for key, val in self.fuel_conf.iteritems():
            pattern = r'%s=[^ ]\S+' % key
            replace = '%s=%s' % (key, val)
            data = re.sub(pattern, replace, data)
        with io.open(file, 'w') as f:
            f.write(data)

    def deploy_env(self):
        dep = CloudDeploy(self.dha, self.fuel_conf['ip'], self.fuel_username,
                          self.fuel_password, self.dea_file, WORK_DIR)
        dep.deploy()

    def deploy(self):
        check_if_root()
        self.setup_dir(TMP_DIR)
        self.collect_fuel_info()
        self.power_off_blades()
        self.install_fuel_master()
        self.cleanup_dir(TMP_DIR)
        self.deploy_env()

def usage():
    print '''
    Usage:
    python deploy.py [-nf] <isofile> <deafile> <dhafile>

    Optional arguments:
      -nf   Do not install Fuel master
    '''

def parse_arguments():
    if (len(sys.argv) < 4 or len(sys.argv) > 5
        or (len(sys.argv) == 5 and sys.argv[1] != '-nf')):
        log('Incorrect number of arguments')
        usage()
        sys.exit(1)
    without_fuel = False
    if len(sys.argv) == 5 and sys.argv[1] == '-nf':
        without_fuel = True
    iso_file = sys.argv[-3]
    dea_file = sys.argv[-2]
    dha_file = sys.argv[-1]
    check_file_exists(iso_file)
    check_file_exists(dea_file)
    check_file_exists(dha_file)
    return (without_fuel, iso_file, dea_file, dha_file)

def main():

    without_fuel, iso_file, dea_file, dha_file = parse_arguments()

    d = AutoDeploy(without_fuel, iso_file, dea_file, dha_file)
    d.deploy()

if __name__ == '__main__':
    main()