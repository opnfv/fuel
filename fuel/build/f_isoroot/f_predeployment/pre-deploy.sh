#!/bin/bash -e
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################


error_exit () {
    echo "$@" >&2
    exit 1
}

get_env() {
   local env_id=${1:-""}

   if [ -z $env_id ]; then
      local n_envs=$(fuel env --list | grep -v -E "^id|^--|^ *$" | wc -l)
      if [ $n_envs -ne 1 ]; then
          echo "Usage: $0 [<env-id>]" >&2
          error_exit "If only a single environment is present it can be left" \
                     "out. Otherwise the environment must be selected"
      fi
      env_id=$(fuel env --list | grep -v -E "^id|^--" | awk '{print $1}')
   else
      if ! fuel --env $env_id environment 2>/dev/null grep -v -E "^id|^--" | \
           grep -q ^$env_id; then
         error_exit "No such environment ID: $env_id"
      fi
   fi
   echo $env_id
}

get_node_uid () {
    cat $1 | grep "^uid: " | sed "s/^uid: '//" | sed "s/'$//"
}

get_node_role () {
    cat $1 | grep "^role: " | sed "s/^role: //"
}

get_next_cic () {
    file=$1

    last=`cat $file | sed 's/.*://' | grep "cic-" | sed 's/cic\-.*sl//' | sort -n | tail -1`
    if [ -z "$last" ]; then
        next=1
    else
        next=$[$last + 2]
    fi
    echo $next
}

get_next_compute () {
    file=$1

    last=`cat $file | sed 's/.*://' | grep "cmp-" | sed 's/cmp\-.*sl//' | sort -n | tail -1`
    if [ -z "$last" ]; then
        next=7
    else
        next=$[$last + 2]
    fi
    echo $next
}

modify_hostnames () {
    env=$1
    file=$2
    for line in `cat $file`
    do
        old=`echo $line | sed 's/:.*//'`
        new=`echo $line | sed 's/.*://'`
        echo "Applying: $old -> $new"

        for dfile in deployment_$env/*.yaml
        do
            sed -i "s/$old/$new/g" $dfile
        done

        for pfile in provisioning_$env/*.yaml
        do
            sed -i "s/$old/$new/g" $pfile
        done
    done
}

setup_hostnames () {
    ENV=$1
    cd ${CONFIGDIR}
    touch hostnames.$ENV

    for dfile in deployment_$ENV/*.yaml
    do
        uid=`get_node_uid $dfile`
        hostname=`grep "^node-$uid:" hostnames.$ENV | sed 's/.*://'`
        if [ -z $hostname ]; then

            pfile=provisioning_$ENV/node-$uid.yaml
            role=`get_node_role $dfile`

            case $role in
                primary-controller)
                    hostname="cic-pod0-sh0-sl`get_next_cic hostnames.$ENV`"
                    ;;
                controller)
                    hostname="cic-pod0-sh0-sl`get_next_cic hostnames.$ENV`"
                    ;;
                compute)
                    hostname="cmp-pod0-sh0-sl`get_next_compute hostnames.$ENV`"
                    ;;
                *)
                    echo "Unknown node type for UID $uid"
                    exit 1
                    ;;
            esac

            echo "node-$uid:$hostname" >> hostnames.$ENV
        else
            echo "Already got hostname $hostname for node-$uid"

        fi
    done

    rm -f hostnames.$ENV.old
    mv hostnames.$ENV hostnames.$ENV.old
    sort hostnames.$ENV.old | uniq > hostnames.$ENV
    modify_hostnames $ENV hostnames.$ENV
}



get_provisioning_info () {
    ENV=$1
    mkdir -p ${CONFIGDIR}
    cd ${CONFIGDIR}
    rm -Rf provisioning_$ENV
    echo "Getting provisioning info..."
    fuel --env $ENV provisioning --default
    if [ $? -ne 0 ]; then
        echo "Error: Could not get provisioning info for env $ENV">&2
        exit 1
    fi
}

get_deployment_info () {
    ENV=$1
    mkdir -p ${CONFIGDIR}
    cd ${CONFIGDIR}
    rm -Rf deployment_$ENV
    echo "Getting deployment info..."
    fuel --env $ENV deployment --default
    if [ $? -ne 0 ]; then
        echo "Error: Could not get deployment info for env $ENV">&2
        exit 1
    fi
}

transform_yaml () {
    ENV=$1
    cd ${CONFIGDIR}
    for dfile in deployment_$ENV/*.yaml
    do
        /opt/opnfv/transform_yaml.py $dfile
    done
}

commit_changes () {
    ENV=$1
    cd ${CONFIGDIR}

    fuel --env $ENV deployment --upload
    fuel --env $ENV provisioning --upload
}

add_yaml_fragment () {
    ENV=$1
    FRAGMENT=${CONFIGDIR}/fragment.yaml.$ENV

    cd ${CONFIGDIR}
    for dfile in deployment_$ENV/*.yaml
    do
        cnt=`grep "^opnfv:" $dfile | wc -l `
        if [ $cnt -eq 0 ]; then
            echo "Adding fragment to $dfile"
            cat $FRAGMENT >> $dfile
       else
            echo "Already have fragment in $dfile"
       fi
    done
}


ip_valid() {
    IP_ADDRESS="$1"
    # Check if the format looks right_
    echo "$IP_ADDRESS" | egrep -qE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' || return 1
    #check that each octect is less than or equal to 255:
    echo $IP_ADDRESS | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <=255 && $4 <= 255 {print "Y" } ' | grep -q Y || return 1
    return 0
}


generate_ntp_entry() {
    FILE=$1
    read -p "NTP server:" NTP_SERVER
    if [ -z "$NTP_SERVER" ]; then
        return 1
    elif confirm_yes "Are you sure you want to add this entry (y/n): "; then
        echo "Confirmed"
        echo "      server $NTP_SERVER" >> $FILE
    fi
}

generate_hostfile_entry() {
    FILE=$1
    read -p "Name:" HOST_NAME
    if [ -z "$HOST_NAME" ]; then
        return 1
    else
        read -p "FQDN:" HOST_FQDN
        read -p "IP:  " HOST_IP
        while ! ip_valid "$HOST_IP"
        do
            echo "This is not a valid IP! Try again."
            read -p "IP:  " HOST_IP
        done
    fi
    if confirm_yes "Are you sure you want to add this entry (y/n): "; then
        echo "Confirmed"
        echo "  - name: $HOST_NAME" >> $FILE
        echo "    address: $HOST_IP" >> $FILE
        echo "    fqdn: $HOST_FQDN" >> $FILE
    else
        echo "Not confirmed"
    fi
    return 0
}

generate_dns_entry() {
    FILE=$1
    PROMPT=$2
    read -p "${PROMPT}:" DNS_IP
    if [ -z "$DNS_IP" ]; then
        return 1
    else
        while ! ip_valid "$DNS_IP"
        do
            echo "This is not a valid IP! Try again."
            read -p "${PROMPT}: " DNS_IP
        done
    fi
    if confirm_yes "Are you sure you want to add this entry (y/n): "; then
        echo "Confirmed"
        echo "    - $DNS_IP" >> $FILE
    else
        echo "Not confirmed"
    fi
    return 0
}

confirm_yes() {
    prompt=$1
    while true
    do
        read -p "$prompt" YESNO
        case $YESNO in
            [Yy])
                return 0
                ;;
            [Nn])
                return 1
                ;;
        esac
    done
}

generate_yaml_fragment() {
    ENV=$1
    FRAGMENT=${CONFIGDIR}/fragment.yaml.$ENV

    if [ -f $FRAGMENT ]; then
        echo "Manual configuration already performed, reusing previous data from $FRAGMENT."
        echo "Press return to continue or ^C to stop."
        read ans
        return
    fi

    echo "opnfv:" > ${FRAGMENT}

    clear
    echo -e "\n\nPre-deployment configuration\n\n"

    echo -e "\n\nIPs for the DNS servers to go into /etc/resolv.conf. You will be"
    echo -e "prompted for one IP at the time. Press return on an empty line"
    echo -e "to complete your input. If no DNS server is specified, the IP of"
    echo -e "the Fuel master will be used instead.\n"

    DNSCICYAML=${CONFIGDIR}/cicdns.yaml.$ENV
    rm -f $DNSCICYAML

    echo -e "\n\n"

    while generate_dns_entry $DNSCICYAML "IP for CIC name servers"
    do
        :
    done

    if [ -f $DNSCICYAML ]; then
        echo "  dns:" >> $FRAGMENT
        echo "    controller:" >> $FRAGMENT
        cat $DNSCICYAML >> $FRAGMENT
    fi


    DNSCMPYAML=${CONFIGDIR}/cmpdns.yaml.$ENV
    rm -f $DNSCMPYAML

    echo -e "\n\n"

    while generate_dns_entry $DNSCMPYAML "IP for compute node name servers"
    do
        :
    done


    if [ -f $DNSCMPYAML ]; then
        if [ ! -f $DNSCICYAML ]; then
            echo "  dns:" >> $FRAGMENT
        fi
        echo "    compute:" >> $FRAGMENT
        cat $DNSCMPYAML >> $FRAGMENT
    fi

    echo -e "\n\nHosts file additions for controllers and compute nodes. You will be"
    echo -e "prompted for name, FQDN and IP for each entry. Press return when prompted"
    echo -e "for a name when you have completed your input.\n"


    HOSTYAML=${CONFIGDIR}/hosts.yaml.$ENV
    rm -f $HOSTYAML
    while generate_hostfile_entry $HOSTYAML
    do
        :
    done

    if [ -f $HOSTYAML ]; then
        echo "  hosts:" >> $FRAGMENT
        cat $HOSTYAML >> $FRAGMENT
    fi

    echo -e "\n\nNTP upstream configuration for controllers.You will be"
    echo -e "prompted for a NTP server each entry. Press return when prompted"
    echo -e "for a NTP serverwhen you have completed your input.\n"


    NTPYAML=${CONFIGDIR}/ntp.yaml.$ENV
    rm -f $NTPYAML
    while generate_ntp_entry $NTPYAML
    do
        :
    done

    if [ -f $NTPYAML ]; then
        echo "  ntp:" >> $FRAGMENT
        echo "    controller: |" >> $FRAGMENT
        cat $NTPYAML >> $FRAGMENT

        echo "    compute: |" >> $FRAGMENT
        for ctl in `find $CONFIGDIR/deployment_$ENV -name '*controller*.yaml'`
        do
           fqdn=`grep "^fqdn:" $ctl | sed 's/fqdn: *//'`
           echo "      server $fqdn" >> $FRAGMENT
        done
    fi

    # If nothing added make sure we get an empty opnfv hash
    # instead of a NULL hash.
    if [ $(wc -l $FRAGMENT | awk '{print $1}') -le 1 ]; then
        echo "opnfv: {}" >$FRAGMENT
    fi
}

ENV=$(get_env "$@")

CONFIGDIR="/var/lib/opnfv"
mkdir -p $CONFIGDIR

get_deployment_info $ENV
# Uncomment the below to enable the control_bond example
#transform_yaml $ENV
get_provisioning_info $ENV
generate_yaml_fragment $ENV
# The feature to change hostnames from node-<n> to cmp- or cic- is disabled.
# To turn it on, uncomment the following line.
#setup_hostnames $ENV
add_yaml_fragment $ENV
commit_changes $ENV
