###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import sys
import common
import io
import yaml
from dea import DeploymentEnvironmentAdapter

check_file_exists = common.check_file_exists

ASTUTE_YAML = '/etc/fuel/astute.yaml'


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


def main():
    dea_file = parse_arguments()
    check_file_exists(ASTUTE_YAML)
    dea = DeploymentEnvironmentAdapter(dea_file)
    with io.open(ASTUTE_YAML) as stream:
        astute = yaml.load(stream)
    transplant(dea, astute)
    with io.open(ASTUTE_YAML, 'w') as stream:
        yaml.dump(astute, stream, default_flow_style=False)


if __name__ == '__main__':
    main()
