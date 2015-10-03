import common
import os
import shutil
import glob
import yaml
import io
import time

N = common.N
E = common.E
R = common.R
RO = common.RO
exec_cmd = common.exec_cmd
run_proc = common.run_proc
parse = common.parse
err = common.err
log = common.log


class Deployment(object):

    def __init__(self, dea, yaml_config_dir, env_id, node_id_roles_dict):
        self.dea = dea
        self.yaml_config_dir = yaml_config_dir
        self.env_id = env_id
        self.node_id_roles_dict = node_id_roles_dict

    def download_deployment_info(self):
        log('Download deployment info for environment %s' % self.env_id)
        deployment_dir = '%s/deployment_%s' \
                         % (self.yaml_config_dir, self.env_id)
        if os.path.exists(deployment_dir):
            shutil.rmtree(deployment_dir)
        exec_cmd('fuel --env %s deployment --default --dir %s'
                 % (self.env_id, self.yaml_config_dir))

    def upload_deployment_info(self):
        log('Upload deployment info for environment %s' % self.env_id)
        exec_cmd('fuel --env %s deployment --upload --dir %s'
                 % (self.env_id, self.yaml_config_dir))

    def config_opnfv(self):
        log('Configure OPNFV settings on environment %s' % self.env_id)
        opnfv_compute = self.dea.get_opnfv('compute')
        opnfv_controller = self.dea.get_opnfv('controller')
        self.download_deployment_info()
        for node_file in glob.glob('%s/deployment_%s/*.yaml'
                                   % (self.yaml_config_dir, self.env_id)):
             with io.open(node_file) as stream:
                 node = yaml.load(stream)
             if node['role'] == 'compute':
                node.update(opnfv_compute)
             else:
                node.update(opnfv_controller)
             with io.open(node_file, 'w') as stream:
                 yaml.dump(node, stream, default_flow_style=False)
        self.upload_deployment_info()

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
            elif env[0][E['status']] == 'error':
                break
            else:
                time.sleep(SLEEP_TIME)
        exec_cmd('rm %s' % LOG_FILE)

        if ready:
            log('Environment %s successfully deployed' % self.env_id)
        else:
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
        exec_cmd('fuel health --env %s --check sanity,smoke --force'
                 % self.env_id)
        log('Health checks passed !')

    def deploy(self):
        self.config_opnfv()
        self.run_deploy()
        self.verify_node_status()
        self.health_check()