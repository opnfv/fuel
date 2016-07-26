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
from dea import DeploymentEnvironmentAdapter

from common import (
    check_file_exists,
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


def transplant(dea, astute):
    fuel_conf = dea.get_fuel_config()
    for key in fuel_conf.iterkeys():
        if key == 'ADMIN_NETWORK':
            for skey in fuel_conf[key].iterkeys():
                astute[key][skey] = fuel_conf[key][skey]
        else:
            astute[key] = fuel_conf[key]
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
    check_file_exists(FUEL_BOOTSTRAP_CLI_YAML)
    dea = DeploymentEnvironmentAdapter(dea_file)
    with io.open(ASTUTE_YAML) as stream:
        astute = yaml.load(stream)
    transplant(dea, astute)
    with io.open(ASTUTE_YAML, 'w') as stream:
        yaml.dump(astute, stream, default_flow_style=False)
    # Update bootstrap config yaml with info from DEA/astute.yaml
    with io.open(FUEL_BOOTSTRAP_CLI_YAML) as stream:
        fuel_bootstrap_cli = yaml.load(stream)
    transplant_bootstrap(astute, fuel_bootstrap_cli)
    with io.open(FUEL_BOOTSTRAP_CLI_YAML, 'w') as stream:
        yaml.dump(fuel_bootstrap_cli, stream, default_flow_style=False)


if __name__ == '__main__':
    main()
