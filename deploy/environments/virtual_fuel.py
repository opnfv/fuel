###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from lxml import etree
from execution_environment import ExecutionEnvironment
import tempfile
import os
import re
import time

from common import (
    exec_cmd,
    check_file_exists,
    check_if_root,
    delete,
    log,
)

VOL_XML_TEMPLATE = '''<volume type='file'>
  <name>{name}</name>
  <capacity unit='{unit}'>{size!s}</capacity>
  <target>
    <format type='{format_type}'/>
  </target>
</volume>'''

DEFAULT_POOL = 'jenkins'

def get_size_and_unit(s):
    p = re.compile('^(\d+)\s*(\D+)')
    m = p.match(s)
    if m == None:
        return None, None
    size = m.groups()[0]
    unit = m.groups()[1]
    return size, unit

class VirtualFuel(ExecutionEnvironment):

    def __init__(self, storage_dir, pxe_bridge, dha_file, root_dir):
        super(VirtualFuel, self).__init__(storage_dir, dha_file, root_dir)
        self.pxe_bridge = pxe_bridge
        self.temp_dir = tempfile.mkdtemp()
        self.vm_name = self.dha.get_node_property(self.fuel_node_id,
                                                  'libvirtName')
        self.vm_template = '%s/%s' % (self.root_dir,
                                      self.dha.get_node_property(
                                          self.fuel_node_id, 'libvirtTemplate'))
        check_file_exists(self.vm_template)
        with open(self.vm_template) as f:
            self.vm_xml = etree.parse(f)

        self.temp_vm_file = '%s/%s' % (self.temp_dir, self.vm_name)
        self.update_vm_template_file()

    def __del__(self):
        delete(self.temp_dir)

    def update_vm_template_file(self):
        with open(self.temp_vm_file, "wc") as f:
            self.vm_xml.write(f, pretty_print=True, xml_declaration=True)

    def del_vm_nics(self):
        interfaces = self.vm_xml.xpath('/domain/devices/interface')
        for interface in interfaces:
            interface.getparent().remove(interface)

    def add_vm_nic(self, bridge):
        interface = etree.Element('interface')
        interface.set('type', 'bridge')
        source = etree.SubElement(interface, 'source')
        source.set('bridge', bridge)
        model = etree.SubElement(interface, 'model')
        model.set('type', 'virtio')

        devices = self.vm_xml.xpath('/domain/devices')
        if devices:
            device = devices[0]
            device.append(interface)
        else:
            err('No devices!')

    def create_volume(self, pool, name, su, img_type='raw'):
        log('Creating image using Libvirt volumes in pool %s, name: %s' %
            (pool, name))
        size, unit = get_size_and_unit(su)
        if size == None:
            err('Could not determine size and unit of %s' % s)

        vol_xml = VOL_XML_TEMPLATE.format(name=name, unit=unit, size=size,
                                          format_type=img_type)
        fname = os.path.join(self.temp_dir, '%s_vol.xml' % name)
        with file(fname, 'w') as f:
            f.write(vol_xml)

        exec_cmd('virsh vol-create --pool %s %s' % (pool, fname))
        vol_path = exec_cmd('virsh vol-path --pool %s %s' % (pool, name))

        delete(fname)

        return vol_path

    def create_image(self, disk_path, disk_size):
        if os.environ.get('LIBVIRT_DEFAULT_URI') == None:
            exec_cmd('qemu-img create -f raw %s %s' % (disk_path, disk_size))
        else:
            pool = DEFAULT_POOL # FIXME
            name = os.path.basename(disk_path)
            disk_path = self.create_volume(pool, name, disk_size)

        return disk_path

    def create_vm(self):
        stamp = time.strftime("%Y%m%d%H%M%S")
        disk_path = '%s/%s-%s.raw' % (self.storage_dir, self.vm_name, stamp)
        disk_sizes = self.dha.get_disks()
        disk_size = disk_sizes['fuel']
        disk_path = self.create_image(disk_path, disk_size)

        self.del_vm_nics()
        for bridge in self.pxe_bridge:
            self.add_vm_nic(bridge)
        self.update_vm_template_file()

        vm_definition_overwrite = self.dha.get_vm_definition('fuel')

        self.define_vm(self.vm_name, self.temp_vm_file, disk_path,
                       vm_definition_overwrite)

    def setup_environment(self):
        check_if_root()
        self.cleanup_environment()
        self.create_vm()

    def cleanup_environment(self):
        self.delete_vm(self.fuel_node_id)
