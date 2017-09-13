#!/usr/bin/python
"""This module does blah blah."""
import argparse
import ipaddress
import yaml
from jinja2 import Environment, FileSystemLoader, Undefined

parser = argparse.ArgumentParser()
parser.add_argument("--yaml", "-y", type=str, required=True)
parser.add_argument("--jinja2", "-j", type=str, required=True)
args = parser.parse_args()

# Custom filter to allow simple IP address operations returning
# a new address from an upper or lower (negative) index
def ipaddr_index(base_address, index):
    return ipaddress.IPv4Address(unicode(base_address)) + int(index)

ENV = Environment(loader=FileSystemLoader('./'))
ENV.filters['ipaddr_index'] = ipaddr_index

with open(args.yaml) as _:
    dict = yaml.safe_load(_)

# Print dictionary generated from yaml (uncomment for debug)
#print dict

# Render template and print generated conf to console
template = ENV.get_template(args.jinja2)
print template.render(conf=dict)
