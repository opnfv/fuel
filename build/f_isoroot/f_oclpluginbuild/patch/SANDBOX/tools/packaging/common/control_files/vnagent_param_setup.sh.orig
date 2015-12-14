#! /bin/bash

OS_VER=$1

CFG_FILE=/etc/contrail/agent_param.tmpl

if [ -f $CFG_FILE ] ; then
    rm -f $CFG_FILE
fi

LOG=/var/log/contrail.log
echo "LOG=$LOG" > $CFG_FILE

CONFIG=/etc/contrail/agent.conf
echo CONFIG=$CONFIG >> $CFG_FILE

prog=/usr/bin/contrail-vrouter-agent
echo prog=$prog >> $CFG_FILE

kmod=/lib/modules/${OS_VER}/extra/net/vrouter/vrouter.ko
echo kmod=$kmod >> $CFG_FILE

pname=$(basename $prog)
echo pname=$pname >> $CFG_FILE

echo "LIBDIR=/usr/lib64" >> $CFG_FILE
echo "VHOST_CFG=/etc/sysconfig/network-scripts/ifcfg-vhost0" >> $CFG_FILE

dev=$(cat /etc/contrail/default_if)
echo dev=__DEVICE__ >> $CFG_FILE
echo vgw_subnet_ip=__VGW_SUBNET_IP__ >> $CFG_FILE
echo vgw_intf=__VGW_INTF_LIST__ >> $CFG_FILE

LOGFILE=/var/log/contrail/vrouter.log
echo "LOGFILE=--log-file=${LOGFILE}" >> $CFG_FILE

echo "$(date): agent_param updated for this server." &>> $LOG
