import ConfigParser, os, socket
import logging as LOG
import pxssh
import sys
import re

LOG_FILE="/var/log/mysql_failover"
try:
    os.remove(LOG_FILE)
except:
    pass

LOG.basicConfig(format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p', filename=LOG_FILE,level=LOG.DEBUG)
ha_vip = {{ HA_VIP }} 
LOG.info("ha_vip: %s" % ha_vip)

#ha_vip = "10.1.0.50"
galera_path = '/etc/mysql/conf.d/wsrep.cnf'
pattern = re.compile(r"gcomm://(?P<prev_ip>.*)")

def ssh_get_hostname(ip):
    try:
        s = pxssh.pxssh()
        s.login("%s" % ip, "root", "root")
        s.sendline('hostname')   # run a command
        s.prompt()             # match the prompt
        result = s.before.strip()      # print everything before the prompt.
        return result.split(os.linesep)[1]
    except pxssh.ExceptionPxssh as e:
        LOG.error("pxssh failed on login.")
	raise

def failover(mode):
    config = ConfigParser.ConfigParser()
    config.optionxform = str
    config.readfp(open(galera_path))
    wsrep_cluster_address = config.get("mysqld", "wsrep_cluster_address")
    wsrep_cluster_address = pattern.match(wsrep_cluster_address).groupdict()["prev_ip"]

    LOG.info("old wsrep_cluster_address = %s" % wsrep_cluster_address)

    if mode == "master":
        # refresh wsrep_cluster_address to null
        LOG.info("I'm being master, set wsrep_cluster_address to null")
	wsrep_cluster_address = ""

    elif mode == "backup":
        # refresh wsrep_cluster_address to master int ip
	hostname = ssh_get_hostname(ha_vip) 
	wsrep_cluster_address = socket.gethostbyname(hostname)
        LOG.info("I'm being slave, set wsrep_cluster_address to master internal ip")

    LOG.info("new wsrep_cluster_address = %s" % wsrep_cluster_address)
    wsrep_cluster_address  = "gcomm://%s" % wsrep_cluster_address
    config.set("mysqld", "wsrep_cluster_address", wsrep_cluster_address)
    with open(galera_path, 'wb') as fp:
        #config.write(sys.stdout)
        config.write(fp)
   
    os.system("service mysql restart")
    LOG.info("failover success!!!")

if __name__ == "__main__":
    LOG.debug("call me: %s" % sys.argv)
    failover(sys.argv[1])
