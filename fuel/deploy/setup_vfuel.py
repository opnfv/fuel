import sys
from lxml import etree
import os

import common
from dha import DeploymentHardwareAdapter

exec_cmd = common.exec_cmd
err = common.err
log = common.log
check_dir_exists = common.check_dir_exists
check_file_exists = common.check_file_exists
check_if_root = common.check_if_root

VFUELNET = '''
iface vfuelnet inet static
        bridge_ports em1
        address 10.40.0.1
        netmask 255.255.255.0
        pre-down iptables -t nat -D POSTROUTING --out-interface p1p1.20 -j MASQUERADE  -m comment --comment "vfuelnet"
        pre-down iptables -D FORWARD --in-interface vfuelnet --out-interface p1p1.20 -m comment --comment "vfuelnet"
        post-up iptables -t nat -A POSTROUTING --out-interface p1p1.20 -j MASQUERADE  -m comment --comment "vfuelnet"
        post-up iptables -A FORWARD --in-interface vfuelnet --out-interface p1p1.20 -m comment --comment "vfuelnet"
'''
VM_DIR = 'baremetal/vm'
FUEL_DISK_SIZE = '30G'
IFACE = 'vfuelnet'
INTERFACE_CONFIG = '/etc/network/interfaces'

class VFuel(object):

    def __init__(self, storage_dir, dha_file):
        self.dha = DeploymentHardwareAdapter(dha_file)
        self.storage_dir = storage_dir
        self.parser = etree.XMLParser(remove_blank_text=True)
        self.fuel_node_id = self.dha.get_fuel_node_id()
        self.file_dir = os.path.dirname(os.path.realpath(__file__))
        self.vm_dir = '%s/%s' % (self.file_dir, VM_DIR)

    def setup_environment(self):
        check_if_root()
        check_dir_exists(self.vm_dir)
        self.setup_networking()
        self.delete_vm()
        self.create_vm()

    def setup_networking(self):
        with open(INTERFACE_CONFIG) as f:
            data = f.read()
        if VFUELNET not in data:
            log('Appending to file %s:\n %s' % (INTERFACE_CONFIG, VFUELNET))
            with open(INTERFACE_CONFIG, 'a') as f:
                f.write('\n%s\n' % VFUELNET)
            if exec_cmd('ip link show | grep %s' % IFACE):
                log('Bring DOWN interface %s' % IFACE)
                exec_cmd('ifdown %s' % IFACE, False)
            log('Bring UP interface %s' % IFACE)
            exec_cmd('ifup %s' % IFACE, False)

    def delete_vm(self):
        vm_name = self.dha.get_node_property(self.fuel_node_id, 'libvirtName')
        r, c = exec_cmd('virsh dumpxml %s' % vm_name, False)
        if c > 0:
            log(r)
            return
        self.undefine_vm_delete_disk(r, vm_name)

    def undefine_vm_delete_disk(self, printout, vm_name):
        disk_files = []
        xml_dump = etree.fromstring(printout, self.parser)
        disks = xml_dump.xpath('/domain/devices/disk')
        for disk in disks:
            sources = disk.xpath('source')
            for source in sources:
                source_file = source.get('file')
                if source_file:
                    disk_files.append(source_file)
        log('Deleting VM %s with disks %s' % (vm_name, disk_files))
        exec_cmd('virsh destroy %s' % vm_name, False)
        exec_cmd('virsh undefine %s' % vm_name, False)
        for file in disk_files:
            exec_cmd('rm -f %s' % file)

    def create_vm(self):
        temp_dir = exec_cmd('mktemp -d')
        vm_name = self.dha.get_node_property(self.fuel_node_id, 'libvirtName')
        vm_template = self.dha.get_node_property(self.fuel_node_id,
                                                 'libvirtTemplate')
        disk_path = '%s/%s.raw' % (self.storage_dir, vm_name)
        exec_cmd('fallocate -l %s %s' % (FUEL_DISK_SIZE, disk_path))
        self.define_vm(vm_name, vm_template, temp_dir, disk_path)
        exec_cmd('rm -fr %s' % temp_dir)

    def define_vm(self, vm_name, vm_template, temp_dir, disk_path):
        log('Creating VM %s with disks %s' % (vm_name, disk_path))
        temp_vm_file = '%s/%s' % (temp_dir, vm_name)
        exec_cmd('cp %s/%s %s' % (self.vm_dir, vm_template, temp_vm_file))
        with open(temp_vm_file) as f:
            vm_xml = etree.parse(f)
            names = vm_xml.xpath('/domain/name')
            for name in names:
                name.text = vm_name
            uuids = vm_xml.xpath('/domain/uuid')
            for uuid in uuids:
                uuid.getparent().remove(uuid)
            disks = vm_xml.xpath('/domain/devices/disk')
            for disk in disks:
                sources = disk.xpath('source')
                for source in sources:
                    source.set('file', disk_path)
        with open(temp_vm_file, 'w') as f:
            vm_xml.write(f, pretty_print=True, xml_declaration=True)
        exec_cmd('virsh define %s' % temp_vm_file)


def usage():
    print '''
    Usage:
    python setup_vfuel.py <storage_directory> <dha_file>

    Example:
            python setup_vfuel.py /mnt/images dha.yaml
    '''

def parse_arguments():
    if len(sys.argv) != 3:
        log('Incorrect number of arguments')
        usage()
        sys.exit(1)
    storage_dir = sys.argv[-2]
    dha_file = sys.argv[-1]
    check_dir_exists(storage_dir)
    check_file_exists(dha_file)
    return storage_dir, dha_file

def main():
    storage_dir, dha_file = parse_arguments()

    vfuel = VFuel(storage_dir, dha_file)
    vfuel.setup_environment()

if __name__ == '__main__':
    main()
