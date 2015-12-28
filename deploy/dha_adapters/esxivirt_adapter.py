#!/usr/bin/python3
# Copyright (c) 2015 Ericsson Canada and others
# daniel.smith@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
#
#  ESXI Adapter for use in FUEL OPNFV CI and AutoDeploy system
# credits: Szilard Cserey (formerly Ericsson)
###############################################################################

import atexit
import hashlib
import json
import ssl

import random
import time
import vcr
import requests

from pyVim import connect
from pyVmomi import vim
from pyVmomi import vmodl

from tools import tasks

from lxml import etree
from hardware_adapter import HardwareAdapter
import tempfile

from common import (
	log,
	exec_cmd,
	err,
	delete,
)

class EsxivirtAdapter(HardwareAdapter):
	
	def __init__(self, yaml_path):
		super(EsxivirtAdapter, self).__init__(yaml_path)
		self.parser = etree.XMLParser(remove_blank_text=True)
		context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
		context.verify_mode = ssl.CERT_NONE
		print("SOMETHING IS CALLING ESXIVIRT ADAPTER")
		host = '10.118.101.12'
		user = 'root'
		password = 'systemabc'
		port = 443
		service_instance = connect.SmartConnect(host=host,
							user=user,
							pwd=password,
							port=int(port),
							sslContext=context)

		atexit.register(connect.Disconnect, service_instance)
		content = service_instance.RetrieveContent()
		
	def setup_networks(self, node_id, service_instance, content, host_name):
		log('Creating vSwitch on %s ' % host_name)
		vm_name = self.get_node_property(node_id, 'esxivirtName')
		num_ports = 512
		host = get_obj(content, [vim.VirtualMachine], host_name)
		host_network_system = host.configManager.networkSystem
		switch_name = vm_name + '-vSwitch'
		log('Creating vSwitch - ' + switch_name + ' for %s ' % vm_name)
		host_spec = vim.host.VirtualSwitch.Specification()
		host_spec.numPorts = num_ports
		host_network_system.AddVirtualSwitch(vswitchName=switch_name, spec=host_spec)
		log('Switch Created Successfull')
		create_portgroups(host, vm_name, switch_name,host_network_system)


	def create_portgroups(host, vm_name, switch_name,host_network_system):
		log('Creating Port Groups on vSwitch %s' % switch_name)
		port_groups = ['PXE-ADMIN', 'OSTACK']	
		for pg in port_groups:
			log('Creating Port Group ' + pg + ' on ' + switch_name)
			port_spec = vim.host.PortGroup.Specification()
			port_spec.name = (vm_name + '-' + pg)
			if pg == 'OSTACK':
				port_spec.vlanId = 4095
			else:
				port_spec.vlanId = 0
			port_spec.vswitchName = switch_name
			security_policy = vim.host.NetworkPolicy.SecurityPolicy()
			security_policy.allowPromiscuous = True
			security_policy.forgedTransmits = True
			security_policy.macChanges = True
			port_spec.policy = vim.host.NetworkPolicy(security=security_policy)
			host_network_system.AddPortGroup(portgrp=port_spec)
			log('Port Group ' + str(port_spec.name) + ' Created Successfully')
			
		
		
		

	
	def create_fuel(self, node_id, vm, content, service_instance, vm_folder, resource_pool, datastore):
		vm_name = self.get_node_property(node_id, 'esxivirtName')
		setup_networks(self, node_id, service_instance,content)
		timestamp = str(int(time.time()))
		fuel_mem = 6144
		fuel_cpu = 6
		fuel_guestId='centos64Guest'
		fuel_vmver='vmx-10'
		log('Will Create FUEL VM Named : ' + vm_name)
		datastore_path = '[' + datastore + '] ' + vm_name
		log('Setting ' + vm_name + 'datastore path to : ' + datastore_path)
		fuel_iso = 'fuel.iso'
		vmx_file = vim.vm.FileInfo(logDirectory=None, vmPathName=datastore_path)
		config = vim.vm.ConfigSpec(name=vm_name, memoryMB=fuel_mem, numCPUs=fuel_cpu,
						files=vmx_file, guestId=fuel_guestId,
						version=fuel_vmver)
		log('Throwing more FUEL on the fire -  starting creations')
		task = vm_folder.CreateVM_Task(config=config,pool=resource_pool)
		tasks.wait_for_tasks(service_instance, [task])


		vm = get_obj(content, [vim.VirtualMachine], vm_name)
		vm_datastore_obj = get_obj(content, [vim.Datastore], datastore)
		vm_network_obj = get_obj(content, [vim.Network], net_name)
		if not vm:
			log('ERROR - FUEL VM Creation Failed - Check host for more info... its dead jim')
			return -1
		else:
			log('FUEL VM Creation Suceeded - Lets bolt the other pieces on')
		add_disk(vm, service_instance)
		add_iso(vm, service_instance, vm_datastore_obj, datastore, fuel_iso)
		setup_networks(self, node_id, service_instance, content, host_name)
		add_nic(self, node_id, vm, service_instance, vm_network_obj, host_name)

	def add_nic(self, node_id, vm, service_instance, vm_network_obj, host_name):
		vm_name = self.get_node_proprety(node_id, 'esxivirtNmae')
		log('Attaching Nics to Vm %s ' % vm_name)
		host = get_obj(content, [vim.VirtualMachine], host_name)
		host_network_system = host.configManager.networkSystem
		for net in host.network:
			print("NET: %" % net)
		
		
	
	def add_iso(vm, service_instance, vm_datastore_obj, datastore, fuel_iso):
		log('Attaching FUEL ISO to FUEL VM')
		spec = vim.vm.ConfigSpec()
		iso_changes = []
		iso_spec = vim.vm.device.VirtualDeviceSpec()
		iso_spec.device = vim.vm.device.VirtualCdrom()
		iso_spec.opreation = vim.vm.device.VirtualDeviceSpec.Operation.add
		iso_spec.device.backing = vim.vm.device.VirtualCdrom.IsoBackingInfo()
		iso_spec.device.backing.datastore = vm_datastore_obj()
		iso_spec.unitNumber = 0
		iso_spec.controllerKey = 200
		iso_spec.connnectable = vim.vm.device.VirtualDevice.ConnectInfo()
		iso_spec.connnectable.startConnected = True
		iso_spec.connnectable.allowGuestControl = False
		iso_spec.connnectable.connected = True
		iso_changes.append(iso_spec)
		spec.deviceChange = iso_changes
		vm.ReconfigVM_Task(spec=spec)
		log('Completed Adding CDROM and Attaching Iso')

		
		
		
	
		
	def add_disk(vm, service_instance):
		log('Setting up Hard Disk for Fuel VM')
		disk_type = 'thin'
		disk_size = '60'
		unit_number = 0
		spec = vim.vm.ConfigSpec()
		log('Creating SCSI Controller')
		controller_changes = []
		controller_spec = vim.vm.device.VirtualDeviceSpec()
		controller_spec.operation = vim.vm.device.VirtualDeviceSpec.Operation.add
		controller_spec.device = vim.vm.device.VirtualLsiLogicSASConroller()
		controller_spec.device.sharedBus = 'noSharing'
		controller_spec.device.key = 1000
		controller_changes.append(controller_spec)
		spec.deviceChange = controller_changes
		vm.ReconfigVM_Task(spec=spec)
		log('SCSI Controller created')
		controller_changes = []
		controller_spec = vim.vm.device.VirtualDeviceSpec()
		controller_spec.operation = vim.vm.device.VirtualDeviceSpec.Operation.add
		controller_spec.device = vim.vm.device.VirtualController()
		controller_spec.device.busNumber = 1
		controller_changes.append(controller_spec)
		spec.deviceChange = controller_changes
		log('IDE Controller created - used for ISO/CDROM')
		log('Creating Hard Disk')
		device_changes = []
		new_disk_kb = int(disk_size) * 1024 * 1024
		disk_spec = vim.vm.device.VirtualDeviceSpec()
		disk_spec.operation = vim.vm.device.VirtualDeviceSpec.Operation.add
		disk_spec.device = vim.vm.device.VirtualDisk()
		disk_spec.device.backing = vim.vm.device.VirtualDisk.FlatVer2BackingInfo()
		if disk_type == 'thin':
			disk_spec.device.backing.thinProvisioned = True
		disk_spec.device.backing.diskMode = 'persistent'	
		disk_spec.device.unitNumber = unit_number
		disk_spec.device.capacityInKB = new_disk_kb
		disk_spec.device.controllerKey = 1000

		
	def node_power_off(self, node_id, service_instance, content):
		vm_name = self.get_node_property(node_id, 'esxivirtName')
		vm = get_obj(content, [vim.VirtualMachine], vm_name)
		log('Power OFF Node %s' % vm_name)
		log("The current powerState is: {0}".format(vm.runtime.powerState))
		if format(vm.runtime.powerState) == "poweredOn":
    			log("Attempting to power off {0}".format(vm.name))
    			task = vm.PowerOffVM_Task()
    			tasks.wait_for_tasks(service_instance, [task])
    			log("{0}".format(task.info.state))

	def node_power_on(self, node_id, service_instance, content):
		vm_name = self.get_node_property(node_id, 'esxivirtName')
		vm = get_obj(content, [vim.VirtualMachine], vm_name)
		if not vm:
		 	log("Fuel VM : " + vm_name + " Not Found - Creating ")
			create_fuel(self, node_id, service_instance, content)	
		log('Power ON Node %s' % vm_name) 
		log("The current powerState is: {0}".format(vm.runtime.powerState))
		if format(vm.runtime.powerState) == "poweredOff":
			log("Attemtptin to power on {0}".format(vm.name))
			task = vm.PowerOffVM_Task()
			tasks.wait_for_tasks(service_instance, [task])
			log("{0}".format(task.info.state))
	
	def node_reset(self, node_id, service_instance, content):
		vm_name = self.get_node_property(node_id, 'esxivirtName')
		vm = get_obj(content, [vim.VirtualMachine], vm_name)
		log('Reset Node %s' % vm_name)
		log("Found: {0}".format(vm.name))
		log("The current powerState is: {0}".format(vm.runtime.powerState))
		task = vm.ResetVM_Task()
		tasks.wait_for_tasks(service_instance, [task])
		log("Reset is  done.")

	def translate(self, boot_order_list, service_instance, content):
		translated = []
		for boot_dev in boot_order_list:
			if boot_dev in DEV:
				translated.append(DEV[boot_dev])
			else:
				err('Boot device %s not recognized' % boot_dev)
		return translated

	def node_set_boot_order(self, node_id, boot_order_list, service_instance, content):
		boot_order_list = self.translate(boot_order_list)
		vm_name = self.get_node_property(node_id, 'esxivirtName')
		vm = get_obj(content, [vim.VirtualMachine], vm_name)
		log('Set boot order %s on Node %s' % (boot_order_list, vm_name))
        	print("INFO - Setting Boot Priority to CDROM in Boot order")
		for dev in boot_order_list:
			if dev == 'pxe':
				bn = vim.option.OptionValue(key='bios.bootDeviceClasses', value='allow:net,hd,cd')
				spec = vim.vm.ConfigSpec()
				spec.extraConfig = [bn]
				task = vm.ReconfigVM_Task(spec)
				tasks.wait_for_tasks(service_instance, [task])
				print("Set boot order to NIC(PXE), HD, ISO")
				log("Set boot order to NIC(PXE), HD, ISO")

			if dev == 'disk':
				bn = vim.option.OptionValue(key='bios.bootDeviceClasses', value='allow:hd,net,cd')
				spec = vim.vm.ConfigSpec()
				spec.extraConfig = [bn]
				task = vm.ReconfigVM_Task(spec)
				tasks.wait_for_tasks(service_instance, [task])
				print("Set boot order to HD, NIC, CD(ISO)")
				log("Set boot order to HD, NIC, CD(ISO)")

			if dev == 'iso':
				bn = vim.option.OptionValue(key='bios.bootDeviceClasses', value='allow:cd,net,hd')
				spec = vim.vm.ConfigSpec()
				spec.extraConfig = [bn]
				task = vm.ReconfigVM_Task(spec)
				tasks.wait_for_tasks(service_instance, [task])
				print("Set boot order to CD(ISO), NIC, HD")
				log("Set boot order to CD(ISO), NIC, HD")
		
	
	def node_eject_iso(self, node_id, service_instance, content):
		vm_name = self.get_node_property(node_id, 'esxivirtName')
		vm = get_obj(content, [vim.VirtualMachine], vm_name)
		device = self.get_name_of_device(vm_name, 'cdrom')
		log("Ejecting ISO from CDROM")
		spec = vim.vm.ConfigSpec()
		fuel_iso = 'fuel.iso'	
		iso_changes = []
		iso_spec = vim.vm.device.VirtualDeviceSpec()
		iso_spec.device = vim.vm.device.VirtualCdrom()
		iso_spec.operation = vim.vm.device.VirtualDeviceSpec.Operation.remove
		iso_spec.device.key = 3000
		iso_changes.append(iso_spec)
		spec.deviceChange = iso_changes
		vm.ReconfigVM_Task(spec=spec)
	

	def node_insert_iso(self, node_id, service_instance, content):
		vm_name = self.get_node_property(node_id,'esxivirtName')
		vm = get_obj(content, [vim.VirtualMachine], vm_name)
		device = self.get_name_of_device(vm_name, 'vim.vm.device.VirtualCdrom')
		log(" Adding ISO/CDROM")
		spec = vim.vm.ConfigSpec()
		fuel_iso = 'fuel.iso'
		iso_changes = []
		iso_spec = vim.vm.device.VirtualCdrom()
		iso_spec.operation = vim.vm.device.VirtualDeviceSpec.Operation.add
		iso_spec.device.backing = vim.vm.device.VirtualCdrom.IsoBackingInfo()
		iso_spec.device.backing.datastore = vm_datastore_obj
		iso_spec.device.backing.fileName = "[%s] %s" % (datastore, "fuel.iso")
		iso_spec.device.unitNumber = 0
		iso_spec.device.controllerKey = 200
		iso_spec.device.connectable = vim.vm.device.VirtualDevice.ConnectInfo()
		iso_spec.device.connectable.startConnected = True
		iso_spec.device.connectable.allowGuestControl = False
		iso_spec.device.connectable.connected = True
		iso_changes.append(iso_spec)
		spec.deviceChange = iso_changes
		vm.ReconfigVM_Task(spec=spec)
		log("Completed Adding CDROM/ISO")
	
	def get_node_pxe_mac(self, node_id, content):
		mac_list = []
		vm_name = self.get_node_property(node_id, 'esxivirtName')
		vm = get_obj(content, [vim.VirtualMachine], vm_name)
		for device in vm.config.hardware.device:
			if type(device).__name__ == 'vim.vm.device.VirtualE1000':
				mac_list.append(device.macAddress)
		return mac_list

	def get_name_of_device(self, vm_name, device_type):
		vm = get_obj(content, [vim.VirtualMachine], vm_name)
        	for device in vm.config.hardware.device:
                	if type(device).__name__ == device_type:
				return device
				
	def get_virt_net_conf_dir(self):
		return self.dha_struct['virtNetConfDir']
			
	def get_obj(content, vimtype, name):	
		obj = None
		container = content.viewManager.CreateContainerView(
			content.rootFolder, vimtype, True)
		for c in container.view:
			log ("DEBUG -  C.name :" + c.name)
			if c.name == name:
				obj = c
				break
		return obj
