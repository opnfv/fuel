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
import json

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


class DeployNotStart(Exception):
    """Unable to start deployment"""


class NodesGoOffline(Exception):
    """Nodes goes offline during deployment"""


class Deployment(object):

    def __init__(self, dea, yaml_config_dir, env_id, node_id_roles_dict,
                 no_health_check, deploy_timeout):
        self.dea = dea
        self.yaml_config_dir = yaml_config_dir
        self.env_id = env_id
        self.node_id_roles_dict = node_id_roles_dict
        self.no_health_check = no_health_check
        self.deploy_timeout = deploy_timeout
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
        abort_after = 60 * int(self.deploy_timeout)
        start = time.time()

        log('Starting deployment of environment %s' % self.env_id)
        deploy_id = None
        ready = False
        timeout = False

        attempts = 0
        while attempts < 3:
            try:
                if time.time() > start + abort_after:
                    timeout = True
                    break
                if not deploy_id:
                    deploy_id = self._start_deploy_task()
                sts, prg, msg = self._deployment_status(deploy_id)
                if sts == 'error':
                    log('Error during deployment: {}'.format(msg))
                    break
                if sts == 'running':
                    log('Environment deployment progress: {}%'.format(prg))
                elif sts == 'ready':
                    ready = True
                    break
                time.sleep(SLEEP_TIME)
            except (DeployNotStart, NodesGoOffline) as e:
                log(e)
                attempts += 1
                deploy_id = None
                time.sleep(SLEEP_TIME * attempts)

        if timeout:
            err('Deployment timed out, environment %s is not operational, '
                'snapshot will not be performed'
                % self.env_id)
        if ready:
            log('Environment %s successfully deployed'
                % self.env_id)
        else:
            self.collect_error_logs()
            err('Deployment failed, environment %s is not operational'
                % self.env_id, self.collect_logs)

    def _start_deploy_task(self):
        out, _ = exec_cmd('fuel2 env deploy {}'.format(self.env_id), False)
        id = self._deployment_task_id(out)
        return id

    def _deployment_task_id(self, response):
        response = str(response)
        if response.startswith('Deployment task with id'):
            for s in response.split():
                if s.isdigit():
                    return int(s)
        raise DeployNotStart('Unable to start deployment: {}'.format(response))

    def _deployment_status(self, id):
        task = self._task_fields(id)
        if task['status'] == 'error':
            if task['message'].endswith(
                    'offline. Remove them from environment and try again.'):
                raise NodesGoOffline(task['message'])
        return task['status'], task['progress'], task['message']

    def _task_fields(self, id):
        try:
            out, _ = exec_cmd('fuel2 task show {} -f json'.format(id), False)
            task_info = json.loads(out)
            properties = {}
            # for 9.0 this can be list of dicts or dict
            # see https://bugs.launchpad.net/fuel/+bug/1625518
            if isinstance(task_info, list):
                for d in task_info:
                        properties.update({d['Field']: d['Value']})
            else:
                return task_info
            return properties
        except ValueError as e:
            err('Unable to fetch task info: {}'.format(e))

    def collect_logs(self):
        log('Cleaning out any previous deployment logs')
        exec_cmd('rm -f /var/log/remote/fuel-snapshot-*', False)
        exec_cmd('rm -f /root/deploy-*', False)
        log('Generating Fuel deploy snap-shot')
        if exec_cmd('fuel snapshot < /dev/null &> snapshot.log', False)[1] <> 0:
            log('Could not create a Fuel snapshot')
        else:
            exec_cmd('mv /root/fuel-snapshot* /var/log/remote/', False)

        log('Collecting all Fuel Snapshot & deploy log files')
        r, _ = exec_cmd('tar -czhf /root/deploy-%s.log.tar.gz /var/log/remote' % time.strftime("%Y%m%d-%H%M%S"), False)
        log(r)

    def verify_node_status(self):
        node_list = parse(exec_cmd('fuel --env %s node' % self.env_id))
        failed_nodes = []
        for node in node_list:
            if node[N['status']] != 'ready':
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
