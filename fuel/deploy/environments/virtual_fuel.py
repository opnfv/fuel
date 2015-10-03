###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from lxml import etree

import common
from execution_environment import ExecutionEnvironment

exec_cmd = common.exec_cmd
log = common.log
check_file_exists = common.check_file_exists
check_if_root = common.check_if_root


class VirtualFuel(ExecutionEnvironment):

    def __init__(self, storage_dir, pxe_bridge, dha_file, root_dir):
        super(VirtualFuel, self).__init__(storage_dir, dha_file, root_dir)
        self.pxe_bridge = pxe_bridge

    def set_vm_nic(self, temp_vm_file):
        with open(temp_vm_file) as f:
            vm_xml = etree.parse(f)
        interfaces = vm_xml.xpath('/domain/devices/interface')
        for interface in interfaces:
            interface.getparent().remove(interface)
        interface = etree.Element('interface')
        interface.set('type', 'bridge')
        source = etree.SubElement(interface, 'source')
        source.set('bridge', self.pxe_bridge)
        model = etree.SubElement(interface, 'model')
        model.set('type', 'virtio')
        devices = vm_xml.xpath('/domain/devices')
        if devices:
            device = devices[0]
            device.append(interface)
        with open(temp_vm_file, 'w') as f:
            vm_xml.write(f, pretty_print=True, xml_declaration=True)

    def create_vm(self):
        temp_dir = exec_cmd('mktemp -d')
        vm_name = self.dha.get_node_property(self.fuel_node_id, 'libvirtName')
        vm_template = '%s/%s' % (self.root_dir,
                                 self.dha.get_node_property(
                                     self.fuel_node_id, 'libvirtTemplate'))
        check_file_exists(vm_template)
        disk_path = '%s/%s.raw' % (self.storage_dir, vm_name)
        disk_sizes = self.dha.get_disks()
        disk_size = disk_sizes['fuel']
        exec_cmd('fallocate -l %s %s' % (disk_size, disk_path))
        temp_vm_file = '%s/%s' % (temp_dir, vm_name)
        exec_cmd('cp %s %s' % (vm_template, temp_vm_file))
        self.set_vm_nic(temp_vm_file)
        self.define_vm(vm_name, temp_vm_file, disk_path)
        exec_cmd('rm -fr %s' % temp_dir)

    def setup_environment(self):
        check_if_root()
        self.cleanup_environment()
        self.create_vm()

    def cleanup_environment(self):
        self.delete_vm(self.fuel_node_id)
