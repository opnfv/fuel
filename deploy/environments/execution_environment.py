###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


from lxml import etree
from dha_adapters.libvirt_adapter import LibvirtAdapter

from common import (
    exec_cmd,
    log,
    delete,
)


class ExecutionEnvironment(object):

    def __init__(self, storage_dir, dha_file, root_dir):
        self.storage_dir = storage_dir
        self.dha = LibvirtAdapter(dha_file)
        self.root_dir = root_dir
        self.parser = etree.XMLParser(remove_blank_text=True)
        self.fuel_node_id = self.dha.get_fuel_node_id()

    def delete_vm(self, node_id):
        vm_name = self.dha.get_node_property(node_id, 'libvirtName')
        r, c = exec_cmd('virsh dumpxml %s' % vm_name, False)
        if c:
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
            delete(file)

    def overwrite_xml(self, vm_xml, vm_definition_overwrite):
        for key, value in vm_definition_overwrite.iteritems():
            if key == 'attribute_equlas':
                continue
            if key == 'value':
                vm_xml.text = str(value)
                return
            if key == 'attribute':
                for attr_key, attr_value in value.iteritems():
                    vm_xml.set(attr_key, str(attr_value))
                return

            if isinstance(value, dict):
                only_when_attribute = value.get('attribute_equlas')
            for xml_element in vm_xml.xpath(key):
                if only_when_attribute:
                    for attr_key, attr_value in \
                            only_when_attribute.iteritems():
                        if attr_value != xml_element.get(attr_key):
                            continue
                self.overwrite_xml(xml_element, value)

    def define_vm(self, vm_name, temp_vm_file, disk_path,
                  vm_definition_overwrite):
        log('Creating VM %s with disks %s' % (vm_name, disk_path))
        with open(temp_vm_file) as f:
            vm_xml = etree.parse(f)
        names = vm_xml.xpath('/domain/name')
        for name in names:
            name.text = vm_name
        uuids = vm_xml.xpath('/domain/uuid')
        for uuid in uuids:
            uuid.getparent().remove(uuid)
        self.overwrite_xml(vm_xml.xpath('/domain')[0],
                           vm_definition_overwrite)
        disks = vm_xml.xpath('/domain/devices/disk')
        for disk in disks:
            if (disk.get('type') == 'file' and
                    disk.get('device') == 'disk'):
                sources = disk.xpath('source')
                for source in sources:
                    disk.remove(source)
                source = etree.Element('source')
                source.set('file', disk_path)
                disk.append(source)
        with open(temp_vm_file, 'w') as f:
            vm_xml.write(f, pretty_print=True, xml_declaration=True)
        exec_cmd('virsh define %s' % temp_vm_file)
