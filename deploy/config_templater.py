#!/usr/bin/env python


import io
import re
import yaml
import sys
from common import(
    err,
    ArgParser,
)


TAG_START = '%{'
TAG_END = '}'
DELIMITER = '/'


def parse_arguments():
    description = '''Process 'template_file' using 'base_file' as source for
template variable substitution.'''

    parser = ArgParser(prog='python %s' % __file__,
                       description=description)
    parser.add_argument('base_file',
                        help='Base YAML file name')
    parser.add_argument('template_file',
                        help='Fragment filename')

    args = parser.parse_args()
    return(args.base_file, args.template_file)


def load_yaml(filename):
    try:
        with io.open(filename) as yaml_file:
            return yaml.load(yaml_file)
    except Exception as error:
        err('Error opening YAML file: %s' % error)


def get_indent(string):
    return len(string) - len(string.lstrip(' '))


def format_fragment(indent, yaml_part):
    result = ''
    is_first_line = True

    for line in yaml_part.splitlines():
        # Skip indenting the first line as it is already indented
        if is_first_line:
            line += '\n'
            is_first_line = False
        else:
            line = ' ' * indent + line + '\n'
        result += line

    return result.rstrip('\n')


def parse_template(base, string, indent):
    string = string.strip(TAG_START).rstrip(TAG_END + '\n')
    path = string.split(DELIMITER)

    for i in path:
        if i in base:
            base = base.get(i)
        else:
            err('Error: key "%s" does not exist in base YAML file' % i)

    if isinstance(base, basestring):
        yaml_fragment = base
    else:
        yaml_fragment = yaml.dump(base, default_flow_style=False)

    return format_fragment(indent, yaml_fragment)


def process_template(base, template_filename):
    with io.open(template_filename) as f:
        result = ''
        for line in f:
            indent = get_indent(line)
            regex = re.compile(re.escape(TAG_START) +
                               r'''[a-z]\w*
                                   (%s[a-z]\w*)*''' % re.escape(DELIMITER) +
                               re.escape(TAG_END),
                               flags=re.IGNORECASE|re.X)
            result += re.sub(regex,
                             lambda match: parse_template(base,
                                                          match.group(0),
                                                          indent),
                             line)

        return result


def main():
    base_file, template_filename = parse_arguments()
    base = load_yaml(base_file)

    print process_template(base, template_filename)


if __name__ == '__main__':
    main()
