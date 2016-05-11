###############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# szilard.cserey@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
###############################################################################


import paramiko
import scp

from common import (
    log,
    err,
)

TIMEOUT = 600

class SSHClient(object):

    def __init__(self, host, username, password):
        self.host = host
        self.username = username
        self.password = password
        self.client = None

    def open(self, timeout=TIMEOUT):
        self.client = paramiko.SSHClient()
        self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.client.connect(self.host, username=self.username,
                            password=self.password, look_for_keys=False,
                            timeout=timeout)

    def close(self):
        if self.client is not None:
            self.client.close()
            self.client = None

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, type, value, traceback):
        self.close()

    def exec_cmd(self, command, check=True, sudo=False, timeout=TIMEOUT):
        if sudo and self.username != 'root':
            command = "sudo -S -p '' %s" % command
        stdin, stdout, stderr = self.client.exec_command(command,
                                                         timeout=timeout)
        if sudo:
            stdin.write(self.password + '\n')
            stdin.flush()
        response = stdout.read().strip()
        error = stderr.read().strip()

        if check:
            if error:
                self.close()
                raise Exception(error)
            else:
                return response
        return response, error

    def run(self, command):
        transport = self.client.get_transport()
        transport.set_keepalive(1)
        chan = transport.open_session()
        chan.exec_command(command)
        while not chan.exit_status_ready():
            if chan.recv_ready():
                data = chan.recv(1024)
                while data:
                    log(data.strip())
                    data = chan.recv(1024)

            if chan.recv_stderr_ready():
                error_buff = chan.recv_stderr(1024)
                while error_buff:
                    log(error_buff.strip())
                    error_buff = chan.recv_stderr(1024)
        return chan.recv_exit_status()

    def scp_get(self, remote, local='.', dir=False):
        try:
            with scp.SCPClient(self.client.get_transport(), sanitize=lambda x: x) as _scp:
                _scp.get(remote, local, dir)
        except Exception as e:
            err(e)

    def scp_put(self, local, remote='.', dir=False):
        try:
            with scp.SCPClient(self.client.get_transport(), sanitize=lambda x: x) as _scp:
                _scp.put(local, remote, dir)
        except Exception as e:
            err(e)
