#!/usr/bin/python
###############################################################################
# Copyright (c) 2016 Ericsson AB and others.
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################

###############################################################################
# Description
###############################################################################

import os
import yaml
import sys
import urllib2
import calendar
import time
import collections
import hashlib
import json

from functools import reduce
from operator import or_
from common import (
    log,
    exec_cmd,
    err,
    warn,
    check_file_exists,
    create_dir_if_not_exists,
    delete,
    check_if_root,
    ArgParser,
)


def parse_arguments():
    parser = ArgParser(prog='python %s' % __file__)
    parser.add_argument('-f', dest='yaml_file', action='store',
                        help='yaml file to use',
                        required=True)
    parser.add_argument('-r', dest='read_yaml', action='store_true',
                        default=True,
                        help='Read value from yaml file',
                        required=False)
    parser.add_argument('-w', dest='write_yaml',
                        action='store_true',
                        default=False,
                        help='Write to yaml file',
                        required=False)
    parser.add_argument('dictionary', metavar='JSON-dict',
                        action='store',
                        help='Write to yaml file')

    args = parser.parse_args()

    kwargs = {'yaml_file': args.yaml_file,
              'read_yaml': args.read_yaml,
              'write_yaml': args.write_yaml,
              'dictionary': args.dictionary}

    return kwargs


def setup_yaml():
    represent_dict_order = lambda self, data: self.represent_mapping('tag:yaml.org,2002:map', data.items())
    yaml.add_representer(collections.OrderedDict, represent_dict_order)


def merge_dicts(dict1, dict2):
    for k in set(dict1).union(dict2):
        if k in dict1 and k in dict2:
            if isinstance(dict1[k], dict) and isinstance(dict2[k], dict):
                yield (k, dict(merge_dicts(dict1[k], dict2[k])))
                continue
            if isinstance(dict1[k], list) and isinstance(dict2[k], list):
                if k == 'versions':
                    yield (k,
                           merge_fuel_plugin_version_list(dict1[k], dict2[k]))
                    continue
                if k == 'networks':
                    yield (k,
                           merge_networks(dict1[k], dict2[k]))
                    continue

            # If one of the values is not a dict nor a list,
            # you can't continue merging it.
            # Value from second dict overrides one in first if exists.
        if k in dict2:
            yield (k, dict2[k])
        else:
            yield (k, dict1[k])


class YamlParse(object):

    def __init__(self):
        self.kwargs = parse_arguments()
        self.yaml_file_dict = dict()
        self.arg_dict = dict()


    def load_yaml_file(self):
        try :
            stream = open(self.kwargs["yaml_file"], "r")
            self.yaml_file_dict = yaml.load(stream)
        except :
            pass

    def load_dict_arg(self):
        self.arg_dict = json.loads(self.kwargs["dictionary"])


    def override_dict_leavs(self):
        self.yaml_file_dict = dict(merge_dicts(self.yaml_file_dict, self.arg_dict))


    def read_dict_leaf(self):
        yaml_file_dict_keys = set(self.yaml_file_dict.keys())
        arg_dict_keys = set(self.arg_dict.keys())
        intersect_keys = yaml_file_dict_keys.intersection(arg_dict_keys)
        modified = {o : (self.yaml_file_dict[o]) for o in intersect_keys if self.yaml_file_dict[o] != self.arg_dict[o]}
        print(modified)


    def write_dict(self):
        with open(self.kwargs["yaml_file"], 'w') as yaml_file:
            yaml.safe_dump(self.yaml_file_dict, yaml_file, encoding='utf-8', allow_unicode=True, default_flow_style=False)


def main():
    setup_yaml()
    yaml_parse = YamlParse()
    yaml_parse.load_yaml_file()
    yaml_parse.load_dict_arg()
    if yaml_parse.kwargs["write_yaml"] == True :
        yaml_parse.override_dict_leavs()
        yaml_parse.write_dict()
    else :
        yaml_parse.read_dict_leaf()


if __name__ == '__main__':
    main()
