import sys
import common
import io
import yaml
from dea import DeploymentEnvironmentAdapter

check_file_exists = common.check_file_exists

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
    astute_yaml = '/etc/fuel/astute.yaml'
    check_file_exists(astute_yaml)
    dea = DeploymentEnvironmentAdapter(dea_file)
    with io.open(astute_yaml) as stream:
        astute = yaml.load(stream)
    transplant(dea, astute)
    with io.open(astute_yaml, 'w') as stream:
        yaml.dump(astute, stream, default_flow_style=False)


if __name__ == '__main__':
    main()