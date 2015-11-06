###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import time
import re

from common import (
    N,
    E,
    exec_cmd,
    run_proc,
    parse,
    err,
    log,
    delete,
)

SEARCH_TEXT = 'Puppet (err)'
LOG_FILE = '/var/log/puppet.log'
GREP_LINES_OF_LEADING_CONTEXT = 100
GREP_LINES_OF_TRAILING_CONTEXT = 100

class Deployment(object):

    def __init__(self, dea, yaml_config_dir, env_id, node_id_roles_dict,
                 no_health_check):
        self.dea = dea
        self.yaml_config_dir = yaml_config_dir
        self.env_id = env_id
        self.node_id_roles_dict = node_id_roles_dict
        self.no_health_check = no_health_check
        self.pattern = re.compile(
            '\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d')

    def collect_error_logs(self):
        for node_id, roles_blade in self.node_id_roles_dict.iteritems():
            log_list = []
            cmd = ('ssh -q node-%s grep \'"%s"\' %s'
                   % (node_id, SEARCH_TEXT, LOG_FILE))
            results, _ = exec_cmd(cmd, False)
            for result in results.splitlines():
                log_msg = ''
                cmd = ('ssh -q node-%s "grep -B%s \\"%s\\" %s"'
                       % (node_id, GREP_LINES_OF_LEADING_CONTEXT, result,
                          LOG_FILE))
                details, _ = exec_cmd(cmd, False)
                details_list = details.splitlines()

                found_prev_log = False
                for i in range(len(details_list) - 2, -1, -1):
                    if self.pattern.match(details_list[i]):
                        found_prev_log = True
                        break
                if found_prev_log:
                    log_msg += '\n'.join(details_list[i:-1]) + '\n'

                cmd = ('ssh -q node-%s "grep -A%s \\"%s\\" %s"'
                       % (node_id, GREP_LINES_OF_TRAILING_CONTEXT, result,
                          LOG_FILE))
                details, _ = exec_cmd(cmd, False)
                details_list = details.splitlines()

                found_next_log = False
                for i in range(1, len(details_list)):
                    if self.pattern.match(details_list[i]):
                        found_next_log = True
                        break
                if found_next_log:
                    log_msg += '\n'.join(details_list[:i])
                else:
                    log_msg += details

                if log_msg:
                   log_list.append(log_msg)

            if log_list:
                role = ('controller' if 'controller' in roles_blade[0]
                        else 'compute host')
                log('_' * 40 + 'Errors in node-%s %s' % (node_id, role)
                    + '_' * 40)
                for log_msg in log_list:
                    print(log_msg + '\n')

    def run_deploy(self):
        WAIT_LOOP = 180
        SLEEP_TIME = 60
        LOG_FILE = 'cloud.log'

        log('Starting deployment of environment %s' % self.env_id)
        run_proc('fuel --env %s deploy-changes | strings | tee %s'
                 % (self.env_id, LOG_FILE))

        ready = False
        for i in range(WAIT_LOOP):
            env = parse(exec_cmd('fuel env --env %s' % self.env_id))
            log('Environment status: %s' % env[0][E['status']])
            r, _ = exec_cmd('tail -2 %s | head -1' % LOG_FILE, False)
            if r:
                log(r)
            if env[0][E['status']] == 'operational':
                ready = True
                break
            elif (env[0][E['status']] == 'error'
                  or env[0][E['status']] == 'stopped'):
                break
            else:
                time.sleep(SLEEP_TIME)
        delete(LOG_FILE)

        if ready:
            log('Environment %s successfully deployed' % self.env_id)
        else:
            self.collect_error_logs()
            err('Deployment failed, environment %s is not operational'
                % self.env_id)

    def verify_node_status(self):
        node_list = parse(exec_cmd('fuel node list'))
        failed_nodes = []
        for node in node_list:
            if node[N['status']] != 'ready':
                failed_nodes.append((node[N['id']], node[N['status']]))

        if failed_nodes:
            summary = ''
            for node, status in failed_nodes:
                summary += '[node %s, status %s]\n' % (node, status)
            err('Deployment failed: %s' % summary)

    def health_check(self):
        log('Now running sanity and smoke health checks')
        r = exec_cmd('fuel health --env %s --check sanity,smoke --force'
                     % self.env_id)
        log(r)
        if 'failure' in r:
            err('Healthcheck failed!')

    def deploy(self):
        self.run_deploy()
        self.verify_node_status()
        if not self.no_health_check:
            self.health_check()
