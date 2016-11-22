###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# peter.barabas@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import subprocess
import sys
import os
import logging
import argparse
import shutil
import errno
import time
import shlex

N = {'id': 0, 'status': 1, 'name': 2, 'cluster': 3, 'ip': 4, 'mac': 5,
     'roles': 6, 'pending_roles': 7, 'online': 8, 'group_id': 9}
E = {'id': 0, 'status': 1, 'name': 2, 'release_id': 3, 'pending_release_id': 4}
R = {'id': 0, 'name': 1, 'state': 2, 'operating_system': 3, 'version': 4}
RO = {'name': 0, 'conflicts': 1}
CWD = os.getcwd()
LOG = logging.getLogger(__name__)
LOG.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(message)s')
out_handler = logging.StreamHandler(sys.stdout)
out_handler.setFormatter(formatter)
LOG.addHandler(out_handler)
LOGFILE = 'autodeploy.log'
if os.path.isfile(LOGFILE):
    os.remove(LOGFILE)
out_handler = logging.FileHandler(LOGFILE, mode='w')
out_handler.setFormatter(formatter)
LOG.addHandler(out_handler)
os.chmod(LOGFILE, 0664)


def mask_arguments(cmd, mask_args, mask_str):
    cmd_line = shlex.split(cmd)
    for pos in mask_args:
        # Don't mask the actual command; also check if we don't reference
        # beyond bounds
        if pos == 0 or pos >= len(cmd_line):
            continue
        cmd_line[pos] = mask_str
    return ' '.join(cmd_line)


def exec_cmd(cmd, check=True, attempts=1, delay=5, verbose=False, mask_args=[], mask_str='*****'):
    masked_cmd = mask_arguments(cmd, mask_args, mask_str)

    # a negative value means forever
    while attempts != 0:
        attempts -= 1
        process = subprocess.Popen(cmd,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE,
                                   shell=True)
        (response, stderr) = process.communicate()
        return_code = process.returncode
        if return_code == 0 or attempts == 0:
            break
        time.sleep(delay)
        if verbose:
            log('%d attempts left: %s' % (attempts, masked_cmd))

    response = response.strip()
    if check:
        if return_code > 0:
            stderr = stderr.strip()
            print("Failed command: " + str(masked_cmd))
            print("Command returned response: " + str(stderr))
            print("Command return code: " + str(return_code))
            raise Exception(stderr)
        else:
            print("Command: " + str(masked_cmd))
            print(str(response))
            return response
    return response, return_code


def run_proc(cmd):
    process = subprocess.Popen(cmd,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT,
                               shell=True)
    return process


def run_proc_wait_terminated(process):
    response = process.communicate()[0].strip()
    return_code = process.returncode
    return response, return_code


def run_proc_kill(process):
    response = process.kill()
    return response


def parse(printout):
    parsed_list = []
    lines = printout.splitlines()
    for l in lines[2:]:
        parsed = [e.strip() for e in l.split('|')]
        parsed_list.append(parsed)
    return parsed_list


def clean(lines):
    parsed_list = []
    parsed = []
    for l in lines.strip().splitlines():
        parsed = []
        cluttered = [e.strip() for e in l.split(' ')]
        for p in cluttered:
            if p:
                parsed.append(p)
        parsed_list.append(parsed)
    return parsed if len(parsed_list) == 1 else parsed_list


def err(message, fun=None, *args):
    LOG.error('%s\n' % message)
    if fun:
        fun(*args)
    sys.exit(1)


def warn(message):
    LOG.warning('%s\n' % message)


def check_file_exists(file_path):
    if not os.path.dirname(file_path):
        file_path = '%s/%s' % (CWD, file_path)
    if not os.access(file_path, os.R_OK):
        err('ERROR: File %s not found\n' % file_path)


def check_dir_exists(dir_path):
    if not os.path.dirname(dir_path):
        dir_path = '%s/%s' % (CWD, dir_path)
    if not os.path.isdir(dir_path):
        err('ERROR: Directory %s not found\n' % dir_path)


def create_dir_if_not_exists(dir_path):
    if not os.path.isdir(dir_path):
        log('Creating directory %s' % dir_path)
        os.makedirs(dir_path)


def delete(f):
    if os.path.isfile(f):
        log('Deleting file %s' % f)
        os.remove(f)
    elif os.path.isdir(f):
        log('Deleting directory %s' % f)
        shutil.rmtree(f)


def commafy(comma_separated_list):
    l = [c.strip() for c in comma_separated_list.split(',')]
    return ','.join(l)


def check_if_root():
    uid = os.getuid()
    if uid != 0:
        err('You need be root to run this application')


def log(message):
    LOG.debug('%s\n' % message)


class ArgParser(argparse.ArgumentParser):

    def error(self, message):
        sys.stderr.write('ERROR: %s\n' % message)
        self.print_help()
        sys.exit(2)


def backup(path):
    src = path
    dst = path + '_orig'
    delete(dst)
    try:
        shutil.copytree(src, dst)
    except OSError as e:
        if e.errno == errno.ENOTDIR:
            shutil.copy(src, dst)
        else:
            raise
