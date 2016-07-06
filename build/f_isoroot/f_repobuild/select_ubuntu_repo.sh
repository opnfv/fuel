#!/bin/bash

BLACKLIST="http://mirrors.se.eu.kernel.org/ubuntu/"
UBUNTU_DISTRO="xenial"
#BLACKLIST+=" http://foo.bar"

cleanup() {
    rm -f $TMPFILE
}

debugmsg() {
    test -n "$DEBUG" && echo "$@" >&2
}


# Check if url is blacklisted in this script
blacklisted () {
  for blackurl in $BLACKLIST
  do
    if [ "$1" == "$blackurl" ]; then
      return 0
    fi
  done
  return 1
}


# Check mirror's integrity
check_mirror () {
    mirror=$1
    status=0
    for packdir in dists/${UBUNTU_DISTRO}-updates/main/binary-amd64 \
        dists/${UBUNTU_DISTRO}-updates/restricted/binary-amd64 \
        dists/${UBUNTU_DISTRO}-updates/universe/binary-amd64 \
        dists/${UBUNTU_DISTRO}-updates/multiverse/binary-amd64 \
        dists/${UBUNTU_DISTRO}-security/main/binary-amd64 \
        dists/${UBUNTU_DISTRO}-security/restricted/binary-amd64 \
        dists/${UBUNTU_DISTRO}-security/universe/binary-amd64 \
        dists/${UBUNTU_DISTRO}-security/multiverse/binary-amd64 \
        dists/${UBUNTU_DISTRO}-proposed/main/binary-amd64 \
        dists/${UBUNTU_DISTRO}-proposed/restricted/binary-amd64 \
        dists/${UBUNTU_DISTRO}-proposed/universe/binary-amd64 \
        dists/${UBUNTU_DISTRO}-proposed/multiverse/binary-amd64 \
        dists/${UBUNTU_DISTRO}/main/binary-amd64 \
        dists/${UBUNTU_DISTRO}/restricted/binary-amd64 \
        dists/${UBUNTU_DISTRO}/universe/binary-amd64 \
        dists/${UBUNTU_DISTRO}/multiverse/binary-amd64 \
        dists/${UBUNTU_DISTRO}-backports/main/binary-amd64 \
        dists/${UBUNTU_DISTRO}-backports/restricted/binary-amd64 \
        dists/${UBUNTU_DISTRO}-backports/universe/binary-amd64 \
        dists/${UBUNTU_DISTRO}-backports/multiverse/binary-amd64
    do
        for packfile in Release Packages.gz
        do
            if [ $status -ne 1 ]; then
                curl --output /dev/null --silent --head --fail \
                    $mirror/$packdir/$packfile
                if [ $? -ne 0 ]; then
                    debugmsg "$mirror: Faulty (at least missing $packdir/$packfile)"
                    status=1
                fi
            fi
        done
    done
    return $status
}

if [ "$1" == "-d" ]; then
    DEBUG=1
fi

# Hardcode for testing purposes
DEBUG=1

TMPFILE=$(mktemp /tmp/mirrorsXXXXX)A
trap cleanup exit

# Generate a list of mirrors considered as "up"
curl -s  https://launchpad.net/ubuntu/+archivemirrors | \
    grep -P -B8 "statusUP|statusSIX" | \
    grep -o -P "(f|ht)tp.*\""  | \
    sed 's/"$//' | sort | uniq > $TMPFILE

# Iterate over "close" mirror, check that they are considered up
# and sane.
for url in $(curl -s http://mirrors.ubuntu.com/mirrors.txt)
do
    if ! grep -q $url $TMPFILE; then
        debugmsg "$url Faulty (detected by Ubuntu)"
    elif blacklisted $url; then
        debugmsg "$url blacklisted"
    elif [ -z $BESTURL ]; then
        if grep -q $url $TMPFILE && check_mirror $url; then
            debugmsg "$url: OK (setting as primary URL)"
            BESTURL=$url
            test -z "$DEBUG" && break
        fi
    else
        grep -q $url $TMPFILE && check_mirror $url && debugmsg "$url: OK"
    fi
done

echo "$BESTURL"
