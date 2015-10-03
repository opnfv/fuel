function deploy_host(){
    cd $WORK_DIR/installer/compass-core
    source $WORK_DIR/venv/bin/activate
    if pip --help | grep -q trusted; then
        pip install -i http://pypi.douban.com/simple -e . --trusted-host pypi.douban.com
    else
        pip install -i http://pypi.douban.com/simple -e .
    fi

    sudo mkdir -p /var/log/compass
    sudo chown -R 777 /var/log/compass

    sudo mkdir -p /etc/compass
    sudo cp -rf conf/setting /etc/compass/.

    cp bin/switch_virtualenv.py.template bin/switch_virtualenv.py
    sed -i "s|\$PythonHome|$VIRTUAL_ENV|g" bin/switch_virtualenv.py
    ssh $ssh_args root@${COMPASS_SERVER} mkdir -p /opt/compass/bin/ansible_callbacks
    scp $ssh_args -r ${COMPASS_DIR}/deploy/status_callback.py root@${COMPASS_SERVER}:/opt/compass/bin/ansible_callbacks/status_callback.py
    
    (sleep 15;reboot_hosts ) &
    bin/client.py --logfile= --loglevel=debug --logdir= --compass_server="${COMPASS_SERVER_URL}" \
    --compass_user_email="${COMPASS_USER_EMAIL}" --compass_user_password="${COMPASS_USER_PASSWORD}" \
    --cluster_name="${CLUSTER_NAME}" --language="${LANGUAGE}" --timezone="${TIMEZONE}" \
    --hostnames="${HOSTNAMES}" --partitions="${PARTITIONS}" --subnets="${SUBNETS}" \
    --adapter_os_pattern="${ADAPTER_OS_PATTERN}" --adapter_name="${ADAPTER_NAME}" \
    --adapter_target_system_pattern="${ADAPTER_TARGET_SYSTEM_PATTERN}" \
    --adapter_flavor_pattern="${ADAPTER_FLAVOR_PATTERN}" \
    --http_proxy="${PROXY}" --https_proxy="${PROXY}" --no_proxy="${IGNORE_PROXY}" \
    --ntp_server="${NTP_SERVER}" --dns_servers="${NAMESERVERS}" --domain="${DOMAIN}" \
    --search_path="${SEARCH_PATH}" --default_gateway="${GATEWAY}" \
    --server_credential="${SERVER_CREDENTIAL}" --local_repo_url="${LOCAL_REPO_URL}" \
    --os_config_json_file="${OS_CONFIG_FILENAME}" --service_credentials="${SERVICE_CREDENTIALS}" \
    --console_credentials="${CONSOLE_CREDENTIALS}" --host_networks="${HOST_NETWORKS}" \
    --network_mapping="${NETWORK_MAPPING}" --package_config_json_file="${PACKAGE_CONFIG_FILENAME}" \
    --host_roles="${HOST_ROLES}" --default_roles="${DEFAULT_ROLES}" --switch_ips="${SWITCH_IPS}" \
    --machines=${machines//\'} --switch_credential="${SWITCH_CREDENTIAL}" \
    --deployment_timeout="${DEPLOYMENT_TIMEOUT}" --${POLL_SWITCHES_FLAG} --dashboard_url="${DASHBOARD_URL}" \
    --cluster_vip="${VIP}"
}
