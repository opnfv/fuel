#set -x
COMPASS_DIR=`cd ${BASH_SOURCE[0]%/*}/../;pwd`
export COMPASS_DIR

apt-get install screen
screen -ls |grep deploy|awk -F. '{print $1}'|xargs kill -9
screen -wipe
#screen -dmSL deploy bash $COMPASS_DIR/ci/launch.sh $*
$COMPASS_DIR/ci/launch.sh $*
