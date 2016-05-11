###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################

import subprocess
import sys
import os

import time
import re

from common import (
    N,
    E,
    exec_cmd,
    run_proc,
    run_proc_wait_terminated,
    run_proc_kill,
    parse,
    err,
    log,
    delete,
)

SEARCH_TEXT = '(err)'
LOG_FILE = '/var/log/puppet.log'
GREP_LINES_OF_LEADING_CONTEXT = 100
GREP_LINES_OF_TRAILING_CONTEXT = 100
LIST_OF_CHAR_TO_BE_ESCAPED = ['[', ']', '"']

class Deployment(object):

    def __init__(self, dea, yaml_config_dir, env_id, node_id_roles_dict,
                 no_health_check, deploy_timeout):
        self.dea = dea
        self.yaml_config_dir = yaml_config_dir
        self.env_id = env_id
        self.node_id_roles_dict = node_id_roles_dict
        self.no_health_check = no_health_check
        self.deploy_timeout = deploy_timeout
        self.snap_timeout = 20
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

                sub_cmd = '"%s" %s' % (result, LOG_FILE)
                for c in LIST_OF_CHAR_TO_BE_ESCAPED:
                    sub_cmd = sub_cmd.replace(c, '\%s' % c)
                grep_cmd = ('grep -B%s %s'
                            % (GREP_LINES_OF_LEADING_CONTEXT, sub_cmd))
                cmd = ('ssh -q node-%s "%s"' % (node_id, grep_cmd))

                details, _ = exec_cmd(cmd, False)
                details_list = details.splitlines()

                found_prev_log = False
                for i in range(len(details_list) - 2, -1, -1):
                    if self.pattern.match(details_list[i]):
                        found_prev_log = True
                        break
                if found_prev_log:
                    log_msg += '\n'.join(details_list[i:-1]) + '\n'

                grep_cmd = ('grep -A%s %s'
                            % (GREP_LINES_OF_TRAILING_CONTEXT, sub_cmd))
                cmd = ('ssh -q node-%s "%s"' % (node_id, grep_cmd))

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
        SLEEP_TIME = 60
        LOG_FILE = 'cloud.log'

        log('Starting deployment of environment %s' % self.env_id)
        deploy_proc = run_proc('fuel --env %s deploy-changes | strings > %s'
                               % (self.env_id, LOG_FILE))

        ready = False
        for i in range(int(self.deploy_timeout)):
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

        p.poll()
        if p.returncode == None:
            log('The process deploying the changes has not yet finished.')
            log('''The file %s won't be deleted''' % LOG_FILE)
        else:
            delete(LOG_FILE)

        if ready:
            log('Environment %s successfully deployed' % self.env_id)
        else:
            self.collect_error_logs()
            err('Deployment failed, environment %s is not operational'
                % self.env_id, self.collect_logs)

        run_proc_wait_terminated(deploy_proc)


    def collect_logs(self):
        SLEEP_TIME = 60
        log('Cleaning out any previous deployment logs')
        exec_cmd('rm -f /var/log/remote/fuel-snapshot-*', False)
        exec_cmd('rm -f /root/deploy-*', False)
        log('Generating Fuel deploy snap-shot')
        for i in range(int(self.snap_timeout)):
            snap_proc = run_proc('fuel snapshot')
            PID = snap_proc.pid
            trace_proc = run_proc('timeout 10 strace -fp %s' % PID)
            trace_output, _ = trace_proc.communicate()
            log(trace_output)
            time.sleep(SLEEP_TIME)

            if exec_cmd('fuel task | grep dump | grep running', False)[1] <> 0:
                results, _ = exec_cmd('fuel task', False)
                log (results)
                log('Retrying')
                run_proc_kill(snap_proc)
            else:
                break

        r, _ = run_proc_wait_terminated(snap_proc)
        log(r)
        exec_cmd('mv /root/fuel-snapshot* /var/log/remote/', False)
        log('Collecting all Fuel Snapshot & deploy log files')
        r, _ = exec_cmd('tar -cvzhf /root/deploy-%s.log.tar.gz /var/log/remote' % time.strftime("%Y%m%d-%H%M%S"), False)
        log(r)


    def verify_node_status(self):
        node_list = parse(exec_cmd('fuel node list'))
        failed_nodes = []
        for node in node_list:
            if node[N['status']] != 'ready' and node[N['cluster']] != 'None':
                failed_nodes.append((node[N['id']], node[N['status']]))

        if failed_nodes:
            summary = ''
            for node, status in failed_nodes:
                summary += '[node %s, status %s]\n' % (node, status)
            err('Deployment failed: %s' % summary, self.collect_logs)

    def health_check(self):
        log('Now running sanity and smoke health checks')
        r = exec_cmd('fuel health --env %s --check sanity,smoke --force' % self.env_id)
        log(r)
        if 'failure' in r:
            err('Healthcheck failed!', self.collect_logs)

    def deploy(self):
        self.run_deploy()
        self.verify_node_status()
        if not self.no_health_check:
            self.health_check()
        self.collect_logs()
