import subprocess
import sys
import os
import logging

N = {'id': 0, 'status': 1, 'name': 2, 'cluster': 3, 'ip': 4, 'mac': 5,
     'roles': 6, 'pending_roles': 7, 'online': 8}
E = {'id': 0, 'status': 1, 'name': 2, 'mode': 3, 'release_id': 4,
     'changes': 5, 'pending_release_id': 6}
R = {'id': 0, 'name': 1, 'state': 2, 'operating_system': 3, 'version': 4}
RO = {'name': 0, 'conflicts': 1}

LOG = logging.getLogger(__name__)
LOG.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(message)s')
out_handler = logging.StreamHandler(sys.stdout)
out_handler.setFormatter(formatter)
LOG.addHandler(out_handler)
out_handler = logging.FileHandler('autodeploy.log', mode='w')
out_handler.setFormatter(formatter)
LOG.addHandler(out_handler)

def exec_cmd(cmd, check=True):
    process = subprocess.Popen(cmd,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT,
                               shell=True)
    response = process.communicate()[0].strip()
    return_code = process.returncode
    if check:
        if return_code > 0:
            err(response)
        else:
            return response
    return response, return_code

def run_proc(cmd):
    process = subprocess.Popen(cmd,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT,
                               shell=True)
    return process

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

def err(message):
    LOG.error('%s\n' % message)
    sys.exit(1)

def check_file_exists(file_path):
    if not os.path.isfile(file_path):
        err('ERROR: File %s not found\n' % file_path)

def check_dir_exists(dir_path):
    if not os.path.isdir(dir_path):
        err('ERROR: Directory %s not found\n' % dir_path)

def check_if_root():
    r = exec_cmd('whoami')
    if r != 'root':
        err('You need be root to run this application')

def log(message):
    LOG.debug('%s\n' % message)
