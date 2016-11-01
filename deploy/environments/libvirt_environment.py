###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from lxml import etree
import glob
from execution_environment import ExecutionEnvironment
import tempfile

from common import (
    exec_cmd,
    log,
    check_dir_exists,
    check_file_exists,
    delete,
)


class LibvirtEnvironment(ExecutionEnvironment):

    def __init__(self, storage_dir, dha_file, dea, root_dir):
        super(LibvirtEnvironment, self).__init__(
            storage_dir, dha_file, root_dir)
        self.dea = dea
        self.network_dir = '%s/%s' % (self.root_dir,
                                      self.dha.get_virt_net_conf_dir())
        self.node_ids = self.dha.get_all_node_ids()
        self.net_names = self.collect_net_names()

    def create_storage(self, node_id, disk_path, disk_sizes):
        role = self.dea.get_node_main_role(node_id, self.fuel_node_id)
        disk_size = disk_sizes[role]
        exec_cmd('qemu-img create -f raw %s %s' % (disk_path, disk_size))

    def create_vms(self):
        temp_dir = tempfile.mkdtemp()
        disk_sizes = self.dha.get_disks()
        for node_id in self.node_ids:
            vm_name = self.dha.get_node_property(node_id, 'libvirtName')
            vm_template = '%s/%s' % (self.root_dir,
                                     self.dha.get_node_property(
                                         node_id, 'libvirtTemplate'))
            check_file_exists(vm_template)
            disk_path = '%s/%s.raw' % (self.storage_dir, vm_name)
            self.create_storage(node_id, disk_path, disk_sizes)
            temp_vm_file = '%s/%s' % (temp_dir, vm_name)
            exec_cmd('cp %s %s' % (vm_template, temp_vm_file))
            vm_definition_overwrite = self.dha.get_vm_definition(
                 self.dea.get_node_main_role(node_id, self.fuel_node_id))
            self.define_vm(vm_name, temp_vm_file, disk_path,
                           vm_definition_overwrite)
        delete(temp_dir)

    def start_vms(self):
        for node_id in self.node_ids:
            self.dha.node_power_on(node_id)

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
            self.delete_vm(node_id)


    def setup_environment(self):
        check_dir_exists(self.network_dir)
        self.cleanup_environment()
        self.create_networks()
        self.create_vms()
        self.start_vms()

    def cleanup_environment(self):
        self.delete_vms()
        self.delete_networks()
