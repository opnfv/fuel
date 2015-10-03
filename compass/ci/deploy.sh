SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONF_NAME=$1
source ${SCRIPT_DIR}/../deploy/prepare.sh || exit $?
source ${SCRIPT_DIR}/../deploy/setup-env.sh || exit $?
source ${SCRIPT_DIR}/../deploy/deploy-vm.sh || exit $?
