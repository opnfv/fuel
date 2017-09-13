#!/usr/bin/python
import argparse
import ipaddress
import yaml
from jinja2 import Environment, FileSystemLoader

PARSER = argparse.ArgumentParser()
PARSER.add_argument("--yaml", "-y", type=str, required=True)
PARSER.add_argument("--jinja2", "-j", type=str, required=True)
ARGS = PARSER.parse_args()

# Processor architecture vs DPKG architecture mapping
DPKG_ARCH_TABLE = {
    'aarch64': 'arm64',
    'x86_64': 'amd64',
}
ARCH_DPKG_TABLE = dict(zip(DPKG_ARCH_TABLE.values(), DPKG_ARCH_TABLE.keys()))

# Custom filter to allow simple IP address operations returning
# a new address from an upper or lower (negative) index
def ipaddr_index(base_address, index):
    """Return IP address in given network at given index"""
    try:
        base_address_str = unicode(base_address)
    #pylint: disable=unused-variable
    except NameError as ex:
        base_address_str = str(base_address)
    return ipaddress.ip_address(base_address_str) + int(index)

# Custom filter to convert between processor architecture
# (as reported by $(uname -m)) and DPKG-style architecture
def dpkg_arch(arch, to_dpkg=True):
    """Return DPKG-compatible from processor arch and vice-versa"""
    if to_dpkg:
        return DPKG_ARCH_TABLE[arch]
    else:
        return ARCH_DPKG_TABLE[arch]

ENV = Environment(loader=FileSystemLoader('./'))
ENV.filters['ipaddr_index'] = ipaddr_index
ENV.filters['dpkg_arch'] = dpkg_arch

with open(ARGS.yaml) as _:
    DICT = yaml.safe_load(_)

# Print dictionary generated from yaml (uncomment for debug)
#print DICT

# Render template and print generated conf to console
TEMPLATE = ENV.get_template(ARGS.jinja2)
#pylint: disable=superfluous-parens
print(TEMPLATE.render(conf=DICT))
