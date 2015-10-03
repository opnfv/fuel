import sys
from lxml import etree
import os
import glob
import common

from dha import DeploymentHardwareAdapter

exec_cmd = common.exec_cmd
err = common.err
log = common.log
check_dir_exists = common.check_dir_exists
check_file_exists = common.check_file_exists
check_if_root = common.check_if_root


class LibvirtEnvironment(object):

    def __init__(self, storage_dir, dha_file):
        self.dha = DeploymentHardwareAdapter(dha_file)
        self.storage_dir = storage_dir
        self.parser = etree.XMLParser(remove_blank_text=True)
        self.file_dir = os.path.dirname(os.path.realpath(__file__))
        self.network_dir = '%s/libvirt/networks' % self.file_dir
        self.vm_dir = '%s/libvirt/vms' % self.file_dir
        self.node_ids = self.dha.get_all_node_ids()
        self.fuel_node_id = self.dha.get_fuel_node_id()
        self.net_names = self.collect_net_names()

    def create_storage(self, node_id, disk_path, disk_sizes):
        if node_id == self.fuel_node_id:
           disk_size = disk_sizes['fuel']
        else:
           role = self.dha.get_node_role(node_id)
           disk_size = disk_sizes[role]
        exec_cmd('fallocate -l %s %s' % (disk_size, disk_path))

    def create_vms(self):
        temp_dir = exec_cmd('mktemp -d')
        disk_sizes = self.dha.get_disks()
        for node_id in self.node_ids:
            vm_name = self.dha.get_node_property(node_id, 'libvirtName')
            vm_template = self.dha.get_node_property(node_id,
                                                     'libvirtTemplate')
            disk_path = '%s/%s.raw' % (self.storage_dir, vm_name)
            self.create_storage(node_id, disk_path, disk_sizes)
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

    def create_networks(self):
        for net_file in glob.glob('%s/*' % self.network_dir):
            exec_cmd('virsh net-define %s' % net_file)
        for net in self.net_names:
            log('Creating network %s' % net)
            exec_cmd('virsh net-autostart %s' % net)
            exec_cmd('virsh net-start %s' % net)

    def delete_networks(self):
        for net in self.net_names:
            log('Deleting network %s' % net)
            exec_cmd('virsh net-destroy %s' % net, False)
            exec_cmd('virsh net-undefine %s' % net, False)

    def get_net_name(self, net_file):
        with open(net_file) as f:
            net_xml = etree.parse(f)
            name_list = net_xml.xpath('/network/name')
            for name in name_list:
                net_name = name.text
        return net_name

    def collect_net_names(self):
        net_list = []
        for net_file in glob.glob('%s/*' % self.network_dir):
            name = self.get_net_name(net_file)
            net_list.append(name)
        return net_list

    def delete_vms(self):
        for node_id in self.node_ids:
            vm_name = self.dha.get_node_property(node_id, 'libvirtName')
            r, c = exec_cmd('virsh dumpxml %s' % vm_name, False)
            if c > 0:
                log(r)
                continue
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

    def setup_environment(self):
        check_if_root()
        check_dir_exists(self.network_dir)
        check_dir_exists(self.vm_dir)
        self.cleanup_environment()
        self.create_vms()
        self.create_networks()

    def cleanup_environment(self):
        self.delete_vms()
        self.delete_networks()


def usage():
    print '''
    Usage:
    python setup_environment.py <storage_directory> <dha_file>

    Example:
            python setup_environment.py /mnt/images dha.yaml
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

    virt = LibvirtEnvironment(storage_dir, dha_file)
    virt.setup_environment()

if __name__ == '__main__':
    main()