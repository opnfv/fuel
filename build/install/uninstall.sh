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


my_exit() {
    cd /tmp
    if [ -d "$MOUNT" ]; then
        fusermount -u $MOUNT
        rmdir $MOUNT
    fi
}
trap my_exit EXIT

echo "Live uninstall is currently disabled as it is not tested"
exit 1

TOP=`pwd`
MOUNT=`mktemp -d /tmp/XXXXXXX`
ssh-copy-id root@10.20.0.2
sshfs root@10.20.0.2:/ $MOUNT

DEST=$MOUNT
REPO=$DEST/var/www/nailgun/ubuntu/fuelweb/x86_64

cd $REPO
if [ ! -f  $REPO/dists/xenial/main/binary-amd64/Packages.backup ]; then
    echo "Error - didn't find backup file for Packages!"
    exit 1
fi

if [ ! -f  $REPO/dists/xenial/main/binary-amd64/Packages.gz.backup ]; then
    echo "Error - didn't find backup file for Packages.gz!"
    exit 1
fi

if [ ! -f  $REPO/dists/xenial/Release.backup ]; then
    echo "Error - didn't find backup file for Release!"
    exit 1
fi

if [ ! -f $DEST/etc/puppet/manifests/site.pp.backup ]; then
    echo "Error - didn't find backup file for site.pp!"
    exit 1
fi

echo "Removing Debian packages:"
cd $TOP/release/pool/main
for deb in *.deb
do
    echo "   $deb"
    rm -Rf $REPO/pool/main/$deb
done
cd $REPO

echo "Removing Puppet modules:"
cd $TOP/puppet/modules
for dir in *
do
    echo "   $dir"
    rm -Rf $DEST/etc/puppet/modules/$dir
done
cd $REPO

echo "Restoring backups of datafiles"

rm -f $REPO/dists/xenial/main/binary-amd64/Packages $REPO/dists/xenial/main/binary-amd64/Packages.gz
rm -f $REPO/dists/xenial/Release $DEST/etc/puppet/manifests/site.pp
mv $REPO/dists/xenial/main/binary-amd64/Packages.backup $REPO/dists/xenial/main/binary-amd64/Packages
mv $REPO/dists/xenial/main/binary-amd64/Packages.gz.backup $REPO/dists/xenial/main/binary-amd64/Packages.gz
mv $REPO/dists/xenial/Release.backup $REPO/dists/xenial/Release
mv $DEST/etc/puppet/manifests/site.pp.backup $DEST/etc/puppet/manifests/site.pp
