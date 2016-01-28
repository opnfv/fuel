#!/bin/bash
mkdir -p /var/log/puppet
exec > >(tee -i /var/log/puppet/bootstrap_admin_node.log)
exec 2>&1

FUEL_RELEASE=$(cat /etc/fuel_release)
ASTUTE_YAML='/etc/fuel/astute.yaml'
BOOTSTRAP_NODE_CONFIG="/etc/fuel/bootstrap_admin_node.conf"
bs_build_log='/var/log/fuel-bootstrap-image-build.log'
bs_status=0
# Backup network configs to this folder. Folder will be created only if
# backup process actually will be.
bup_folder="/var/bootstrap_admin_node_bup_$(date +%Y-%m-%d-%H-%M-%S)/"
### Long messages inside code makes them more complicated to read...
# bootstrap messages
# FIXME fix help links
bs_skip_message="WARNING: Ubuntu bootstrap build has been skipped. \
Please build and activate bootstrap manually with CLI command \
\`fuel-bootstrap build --activate\`. \
While you don't activate any bootstrap - new nodes cannot be discovered \
and added to cluster. \
For more information please visit \
https://docs.mirantis.com/openstack/fuel/fuel-master/"
bs_error_message="WARNING: Failed to build the bootstrap image, see $bs_build_log \
for details. Perhaps your Internet connection is broken. Please fix the \
problem and run \`fuel-bootstrap build --activate\`. \
While you don\'t activate any bootstrap - new nodes cannot be discovered \
and added to cluster. \
For more information please visit \
https://docs.mirantis.com/openstack/fuel/fuel-master/"
bs_progress_message="There is no active bootstrap. Bootstrap image building \
is in progress. Usually it takes 15-20 minutes. It depends on your internet \
connection and hardware performance. Please reboot failed to discover nodes \
after bootstrap image become available."
bs_done_message="Default bootstrap image building done. Now you can boot new \
nodes over PXE, they will be discovered and become available for installing \
OpenStack on them"
bs_centos_message="WARNING: Deprecated Centos bootstrap has been chosen \
and activated. Now you can boot new nodes over PXE, they will be discovered \
and become available for installing OpenStack on them."
# Update issues messages
update_warn_message="There is an issue connecting to the Fuel update repository. \
Please fix your connection prior to applying any updates. \
Once the connection is fixed, we recommend reviewing and applying \
Maintenance Updates for this release of Mirantis OpenStack: \
https://docs.mirantis.com/openstack/fuel/fuel-${FUEL_RELEASE}/\
release-notes.html#maintenance-updates"
update_done_message="We recommend reviewing and applying Maintenance Updates \
for this release of Mirantis OpenStack: \
https://docs.mirantis.com/openstack/fuel/fuel-${FUEL_RELEASE}/\
release-notes.html#maintenance-updates"
fuelmenu_fail_message="Fuelmenu was not able to generate '/etc/fuel/astute.yaml' file! \
Please, restart it manualy using 'fuelmenu' command."

function countdown() {
  local i
  sleep 1
  for ((i=$1-1; i>=1; i--)); do
    printf '\b\b\b\b%04d' "$i"
    sleep 1
  done
}

function fail() {
  echo "ERROR: Fuel node deployment FAILED! Check /var/log/puppet/bootstrap_admin_node.log for details" 1>&2
  exit 1
}
# LANG variable is a workaround for puppet-3.4.2 bug. See LP#1312758 for details
export LANG=en_US.UTF8
export ADMIN_INTERFACE=eth0

showmenu="no"
if [ -f /etc/fuel/bootstrap_admin_node.conf ]; then
  . /etc/fuel/bootstrap_admin_node.conf
  echo "Applying admin interface '$ADMIN_INTERFACE'"
fi

echo "Applying default Fuel settings..."
set -x
fuelmenu --save-only --iface=$ADMIN_INTERFACE
set +x
echo "Done!"

### OPNFV addition BEGIN
shopt -s nullglob
for script in /opt/opnfv/bootstrap/pre.d/*.sh
do
  echo "Pre script: $script" >> /root/pre.log 2>&1
  $script >> /root/pre.log 2>&1
done
shopt -u nullglob
### OPNFV addition END

# Enable sshd
systemctl enable sshd
systemctl start sshd

if [[ "$showmenu" == "yes" || "$showmenu" == "YES" ]]; then
  fuelmenu
  else
  #Give user 15 seconds to enter fuelmenu or else continue
  echo
  echo -n "Press a key to enter Fuel Setup (or press ESC to skip)...   15"
  countdown 15 & pid=$!
  if ! read -s -n 1 -t 15 key; then
    echo -e "\nSkipping Fuel Setup..."
  else
    { kill "$pid"; wait $!; } 2>/dev/null
    case "$key" in
      $'\e')  echo "Skipping Fuel Setup.."
              ;;
      *)      echo -e "\nEntering Fuel Setup..."
              fuelmenu
              ;;
    esac
  fi
fi

systemctl reload sshd

# Enable iptables
systemctl enable iptables.service
systemctl start iptables.service


if [ ! -f "${ASTUTE_YAML}" ]; then
  echo ${fuelmenu_fail_message}
  fail
fi

systemctl reload sshd

# Enable iptables
systemctl enable iptables.service
systemctl start iptables.service


if [ "$wait_for_external_config" == "yes" ]; then
  wait_timeout=3000
  pidfile=/var/lock/wait_for_external_config
  echo -n "Waiting for external configuration (or press ESC to skip)...
$wait_timeout"
  countdown $wait_timeout & countdown_pid=$!
  exec -a wait_for_external_config sleep $wait_timeout & wait_pid=$!
  echo $wait_pid > $pidfile
  while ps -p $countdown_pid &> /dev/null && ps -p $wait_pid &>/dev/null; do
    read -s -n 1 -t 2 key
    case "$key" in
      $'\e')   echo -e "\b\b\b\b abort on user input"
               break
               ;;
      *)       ;;
    esac
  done
  { kill $countdown_pid $wait_pid & wait $!; }
  rm -f $pidfile
fi


#Reread /etc/sysconfig/network to inform puppet of changes
. /etc/sysconfig/network
hostname "$HOSTNAME"

# XXX: ssh keys which should be included into the bootstrap image are
# generated during containers deployment. However cobbler checkfs for
# a kernel and initramfs when creating a profile, which poses chicken
# and egg problem. Fortunately cobbler is pretty happy with empty files
# so it's easy to break the loop.
make_ubuntu_bootstrap_stub () {
	local bootstrap_dir='/var/www/nailgun/bootstrap/ubuntu'
	mkdir -p $bootstrap_dir
	for item in linux initramfs.img; do
		touch "$bootstrap_dir/$item"
	done
}

get_bootstrap_flavor () {
	python <<-EOF
	from yaml import safe_load
	with open("$ASTUTE_YAML", 'r') as f:
	    conf = safe_load(f).get('BOOTSTRAP', {})
	print(conf.get('flavor', 'centos').lower())
	EOF
}

get_bootstrap_skip () {
	python <<-EOF
	from yaml import safe_load
	with open("$ASTUTE_YAML", 'r') as f:
	    conf = safe_load(f).get('BOOTSTRAP', {})
	print(conf.get('skip_default_img_build', False))
	EOF
}

set_ui_bootstrap_error () {
        # This notify can't be closed or removed by user.
        # For remove notify - send empty string.
        local message=$1
        python <<-EOF
	from fuel_bootstrap.utils import notifier
	notifier.notify_webui('${message}')
	EOF
}

# Actually build the bootstrap image
build_ubuntu_bootstrap () {
        local ret=1
        echo ${bs_progress_message} >&2
        set_ui_bootstrap_error "${bs_progress_message}" >&2
        if fuel-bootstrap -v --debug build --activate >>"$bs_build_log" 2>&1; then
          ret=0
          fuel notify --topic "done" --send "${bs_done_message}"
        else
          ret=1
          set_ui_bootstrap_error "${bs_error_message}" >&2
        fi
        # perform hard-return from func
        # this part will update input $1 variable
        local  __resultvar=$1
        eval $__resultvar="'${ret}'"
        return $ret
}


# Create empty files to make cobbler happy
# (even if we don't use Ubuntu based bootstrap)
make_ubuntu_bootstrap_stub

service docker start

if [ -f /root/.build_images ]; then
  #Fail on all errors
  set -e
  trap fail EXIT

  echo "Loading Fuel base image for Docker..."
  docker load -i /var/www/nailgun/docker/images/fuel-images.tar

  echo "Building Fuel Docker images..."
  WORKDIR=$(mktemp -d /tmp/docker-buildXXX)
  SOURCE=/var/www/nailgun/docker
  REPO_CONT_ID=$(docker -D run -d -p 80 -v /var/www/nailgun:/var/www/nailgun fuel/centos sh -c 'mkdir /var/www/html/os;ln -sf /var/www/nailgun/centos/x86_64 /var/www/html/os/x86_64;/usr/sbin/apachectl -DFOREGROUND')
  RANDOM_PORT=$(docker port $REPO_CONT_ID 80 | cut -d':' -f2)

  for imagesource in /var/www/nailgun/docker/sources/*; do
    if ! [ -f "$imagesource/Dockerfile" ]; then
      echo "Skipping ${imagesource}..."
      continue
    fi
    image=$(basename "$imagesource")
    cp -R "$imagesource" $WORKDIR/$image
    mkdir -p $WORKDIR/$image/etc
    cp -R /etc/puppet /etc/fuel $WORKDIR/$image/etc
    sed -e "s/_PORT_/${RANDOM_PORT}/" -i $WORKDIR/$image/Dockerfile
    sed -e 's/production:.*/production: "docker-build"/' -i $WORKDIR/$image/etc/fuel/version.yaml
    docker build -t fuel/${image}_${FUEL_RELEASE} $WORKDIR/$image
  done
  docker rm -f $REPO_CONT_ID
  rm -rf "$WORKDIR"

  #Remove trap for normal deployment
  trap - EXIT
  set +e
else
  echo "Loading docker images. (This may take a while)"
  docker load -i /var/www/nailgun/docker/images/fuel-images.tar
fi

# apply puppet
puppet apply --detailed-exitcodes -d -v /etc/puppet/modules/nailgun/examples/host-only.pp
if [ $? -ge 4 ];then
  fail
fi

rmdir /var/log/remote && ln -s /var/log/docker-logs/remote /var/log/remote

dockerctl check || fail
bash /etc/rc.local

### OPNFV addition BEGIN
shopt -s nullglob
for script in /opt/opnfv/bootstrap/post.d/*.sh
do
  echo "Post script: $script" >> /root/post.log 2>&1
  $script >> /root/post.log 2>&1
done
shopt -u nullglob
### OPNFV addition END

if [ "`get_bootstrap_flavor`" = "ubuntu" ]; then
	build_ubuntu_bootstrap || true
fi


# Enable updates repository
cat > /etc/yum.repos.d/mos${FUEL_RELEASE}-updates.repo << EOF
[mos${FUEL_RELEASE}-updates]
name=mos${FUEL_RELEASE}-updates
baseurl=http://mirror.fuel-infra.org/mos-repos/centos/mos${FUEL_RELEASE}-centos6-fuel/updates/x86_64/
gpgcheck=0
skip_if_unavailable=1
EOF

# Enable security repository
cat > /etc/yum.repos.d/mos${FUEL_RELEASE}-security.repo << EOF
[mos${FUEL_RELEASE}-security]
name=mos${FUEL_RELEASE}-security
baseurl=http://mirror.fuel-infra.org/mos-repos/centos/mos${FUEL_RELEASE}-centos6-fuel/security/x86_64/
gpgcheck=0
skip_if_unavailable=1
EOF

#Check if repo is accessible
echo "Checking for access to updates repository..."
repourl=$(grep baseurl /etc/yum.repos.d/*updates* 2>/dev/null | cut -d'=' -f2- | head -1)
if urlaccesscheck check "$repourl" ; then
  UPDATE_ISSUES=0
else
  UPDATE_ISSUES=1
fi

if [ $UPDATE_ISSUES -eq 1 ]; then
  message="There is an issue connecting to the Fuel update repository. \
Please fix your connection prior to applying any updates. \
Once the connection is fixed, we recommend reviewing and applying \
Maintenance Updates for this release of Mirantis OpenStack: \
https://docs.mirantis.com/openstack/fuel/fuel-${FUEL_RELEASE}/\
release-notes.html#maintenance-updates"
  level="warning"
else
  message="We recommend reviewing and applying Maintenance Updates \
for this release of Mirantis OpenStack: \
https://docs.mirantis.com/openstack/fuel/fuel-${FUEL_RELEASE}/\
release-notes.html#maintenance-updates"
  level="done"
fi
echo
echo "*************************************************"
echo -e "${message}"
echo "*************************************************"
echo "Sending notification to Fuel UI..."
fuel notify --topic "${level}" --send "${message}"

# TODO(kozhukalov) If building of bootstrap image fails
# and if this image was supposed to be a default bootstrap image
# we need to warn a user about this and give her
# advice how to treat this.

echo "Fuel node deployment complete!"
