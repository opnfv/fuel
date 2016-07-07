#!/usr/bin/env python
###############################################################################
# Copyright (c) 2016 Ericsson AB and others.
# peter.barabas@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import io
import re
import yaml
from common import(
    err,
    ArgParser,
)


TAG_START = '%{'
TAG_END = '}'
DELIMITER = '/'


class Templater(object):
    def __init__(self, base_file, template_file, output_file):
        self.template_file = template_file
        self.output_file = output_file
        self.base = self.load_yaml(base_file)

    def load_yaml(self, filename):
        try:
            with io.open(filename) as yaml_file:
                return yaml.load(yaml_file)
        except Exception as error:
            err('Error opening YAML file: %s' % error)

    def get_indent(self, line):
        return len(line) - len(line.lstrip(' '))

    def format_fragment(self, fragment, indent):
        result = ''
        is_first_line = True

        for line in fragment.splitlines():
            # Skip indenting the first line as it is already indented
            if is_first_line:
                line += '\n'
                is_first_line = False
            else:
                line = ' ' * indent + line + '\n'

            result += line

        return result.rstrip('\n')

    def format_substitution(self, string):
        if isinstance(string, basestring):
            return string
        else:
            return yaml.dump(string, default_flow_style=False)

    def parse_interface_tag(self, tag):
        # Remove 'interface(' prefix, trailing ')' and split arguments
        args = tag[len('interface('):].rstrip(')').split(',')

        if len(args) == 1 and not args[0]:
            err('No arguments for interface().')
        elif len(args) == 2 and (not args[0] or not args[1]):
            err('Empty argument for interface().')
        elif len(args) > 2:
            err('Too many arguments for interface().')
        else:
            return args

    def get_interface_from_network(self, interfaces, network):
        nics = self.base[interfaces]
        for nic in nics:
            if network in nics[nic]:
                return nic

        err('Network not found: %s' % network)

    def get_role_interfaces(self, role):
        nodes = self.base['nodes']
        for node in nodes:
            if role in node['role']:
                return node['interfaces']

        err('Role not found: %s' % role)

    def lookup_interface(self, args):
        nodes = self.base['nodes']

        if len(args) == 1:
            interfaces = nodes[0]['interfaces']
        if len(args) == 2:
            interfaces = self.get_role_interfaces(args[1])

        return self.get_interface_from_network(interfaces, args[0])

    def parse_tag(self, tag, indent):
        fragment = ''

        if 'interface(' in tag:
            args = self.parse_interface_tag(tag)
            fragment = self.lookup_interface(args)
        else:
            path = tag.split(DELIMITER)
            fragment = self.base
            for i in path:
                if i in fragment:
                    fragment = fragment.get(i)
                else:
                    err('Error: key "%s" does not exist in base YAML file' % i)
                    
            fragment = self.format_substitution(fragment)

        return self.format_fragment(fragment, indent)

    def parse(self):
        result = ''

        regex = re.compile(re.escape(TAG_START) + r'([a-z].+)' + re.escape(TAG_END),
                           flags=re.IGNORECASE)
        with io.open(self.template_file) as f:
            for line in f:
                indent = self.get_indent(line)
                result += re.sub(regex,
                                 lambda match: self.parse_tag(match.group(1), indent),
                                 line)

        return result  

    def run(self):
       return self.parse()


def parse_arguments():
    description = '''Process 'template_file' using 'base_file' as source for
template variable substitution and write the results to 'output_file'.'''

    parser = ArgParser(prog='python %s' % __file__,
                       description=description)
    parser.add_argument('base_file',
                        help='Base YAML filename')
    parser.add_argument('template_file',
                        help='Fragment filename')
    parser.add_argument('output_file',
                        help='Output filename')

    args = parser.parse_args()
    return(args.base_file, args.template_file, args.output_file)


def main():
    base_file, template_file, output_file = parse_arguments()

    templater = Templater(base_file, template_file, output_file)
    print templater.run()


if __name__ == '__main__':
    main()
