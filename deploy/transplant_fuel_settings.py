###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import sys
import io
import yaml
import re
import os
from dea import DeploymentEnvironmentAdapter

from common import (
    check_file_exists,
    exec_cmd,
    log,
)

ASTUTE_YAML = '/etc/fuel/astute.yaml'
FUEL_BOOTSTRAP_CLI_YAML = '/opt/opnfv/fuel_bootstrap_cli.yaml'


def usage():
    print '''
    Usage:
    python transplant_fuel_settings.py <deafile>
    '''


def parse_arguments():
    if len(sys.argv) != 2:
        usage()
        sys.exit(1)
    dea_file = sys.argv[-1]
    check_file_exists(dea_file)
    return dea_file

def write_ifcfg_file(key, fuel_conf):
    config = ('BOOTPROTO=none\n'
              'ONBOOT=yes\n'
              'TYPE=Ethernet\n'
              'NM_CONTROLLED=yes\n')
    for skey in ('ipaddress', 'device', 'netmask', 'gateway'):
        if not fuel_conf[key].get(skey):
            log('Warning: missing key %s for %s' % (skey, key))
            config += '%s=\n' % skey.upper()
        elif skey == 'ipaddress':
            config += 'IPADDR=%s\n' % fuel_conf[key][skey]
        else:
            config += '%s=%s\n' % (skey.upper(), fuel_conf[key][skey])

    fname = os.path.join('/etc/sysconfig/network-scripts/',
                         key.lower().replace('_','-'))
    with open(fname, 'wc') as f:
        f.write(config)

def transplant(dea, astute):
    fuel_conf = dea.get_fuel_config()
    require_network_restart = False
    for key in fuel_conf.iterkeys():
        if key == 'ADMIN_NETWORK':
            for skey in fuel_conf[key].iterkeys():
                astute[key][skey] = fuel_conf[key][skey]
        elif re.match('^IFCFG', key):
            log('Adding interface configuration for: %s' % key.lower())
            require_network_restart = True
            write_ifcfg_file(key, fuel_conf)
            if astute.has_key(key):
                astute.pop(key, None)
        else:
            astute[key] = fuel_conf[key]
    if require_network_restart:
        admin_ifcfg = '/etc/sysconfig/network-scripts/ifcfg-eth0'
        exec_cmd('echo "DEFROUTE=no" >> %s' % admin_ifcfg)
        log('At least one interface was reconfigured, restart network manager')
        exec_cmd('systemctl restart network')
    return astute


def transplant_bootstrap(astute, fuel_bootstrap_cli):
    if 'BOOTSTRAP' in astute:
        for skey in astute['BOOTSTRAP'].iterkeys():
            # FIXME: astute.yaml repos point to public ones instead of
            # local mirrors, this filter should be removed when in sync
            if skey != 'repos':
                fuel_bootstrap_cli[skey] = astute['BOOTSTRAP'][skey]
    return fuel_bootstrap_cli

def main():
    dea_file = parse_arguments()
    check_file_exists(ASTUTE_YAML)
    # Temporarily disabled for Fuel 10.
    # check_file_exists(FUEL_BOOTSTRAP_CLI_YAML)
    dea = DeploymentEnvironmentAdapter(dea_file)
    log('Reading astute file %s' % ASTUTE_YAML)
    with io.open(ASTUTE_YAML) as stream:
        astute = yaml.load(stream)
    log('Initiating transplant')
    transplant(dea, astute)
    with io.open(ASTUTE_YAML, 'w') as stream:
        yaml.dump(astute, stream, default_flow_style=False)
    log('Transplant done')
    # Update bootstrap config yaml with info from DEA/astute.yaml
    # Temporarily disabled for Fuel 10.
    # with io.open(FUEL_BOOTSTRAP_CLI_YAML) as stream:
    #     fuel_bootstrap_cli = yaml.load(stream)
    # transplant_bootstrap(astute, fuel_bootstrap_cli)
    # with io.open(FUEL_BOOTSTRAP_CLI_YAML, 'w') as stream:
    #     yaml.dump(fuel_bootstrap_cli, stream, default_flow_style=False)


if __name__ == '__main__':
    main()
