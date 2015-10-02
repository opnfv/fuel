#!/bin/bash
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

exit_handler() {
    rm -Rf $tmpnewdir
    fusermount -u $tmporigdir 2>/dev/null
    test -d $tmporigdir && rmdir $tmporigdir
}

trap exit_handler exit

error_exit() {
  echo "$@"
  exit 1
}

if [ $# -ne 8 ]; then
    error_exit "Input argument error"
fi

top=$(cd `dirname $0`; pwd)
origiso=$(cd `dirname $1`; echo `pwd`/`basename $1`)
newiso=$(cd `dirname $2`; echo `pwd`/`basename $2`)
tmpdir=$3
fuelIp=$4
fuelNetmask=$5
fuelGateway=$6
fuelHostname=$7
fuelDns=$8

tmporigdir=${tmpdir}/origiso
tmpnewdir=${tmpdir}/newiso

test -f $origiso || error_exit "Could not find origiso $origiso"
test -d $tmpdir || error_exit "Could not find tmpdir $tmpdir"


if [ "`whoami`" != "root" ]; then
  error_exit "You need be root to run this script"
fi

echo "Copying..."
rm -Rf $tmpnewdir || error_exit "Failed deleting old ISO copy dir"
mkdir -p $tmporigdir $tmpnewdir
fuseiso $origiso $tmporigdir || error_exit "Failed to FUSE mount ISO"
cd $tmporigdir
find . | cpio -pd $tmpnewdir || error_exit "Failed to copy FUSE ISO with cpio"
cd $tmpnewdir
fusermount -u $tmporigdir || error_exit "Failed to FUSE unmount ISO"
rmdir $tmporigdir || error_exit "Failed to delete original FUSE ISO directory"
chmod -R 755 $tmpnewdir || error_exit "Failed to set protection on new ISO dir"

echo "Patching..."
cd $tmpnewdir
# Patch ISO to make it suitable for automatic deployment
cat $top/ks.cfg.patch | patch -p0 || error_exit "Failed patching ks.cfg"
rm -rf .rr_moved

# Add dynamic Fuel content
echo "isolinux.cfg before: `grep netmask isolinux/isolinux.cfg`"
sed -i "s/ ip=[^ ]*/ ip=$fuelIp/" isolinux/isolinux.cfg
sed -i "s/ gw=[^ ]*/ gw=$fuelGateway/" isolinux/isolinux.cfg
sed -i "s/ dns1=[^ ]*/ dns1=$fuelDns/" isolinux/isolinux.cfg
sed -i "s/ netmask=[^ ]*/ netmask=$fuelNetmask/" isolinux/isolinux.cfg
sed -i "s/ hostname=[^ ]*/ hostname=$fuelHostname/" isolinux/isolinux.cfg
sed -i "s/ showmenu=[^ ]*/ showmenu=yes/" isolinux/isolinux.cfg
echo "isolinux.cfg after: `grep netmask isolinux/isolinux.cfg`"

rm -vf $newiso
echo "Creating iso $newiso"
mkisofs -quiet -r  \
  -J -R -b isolinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  --hide-rr-moved \
  -x "lost+found" -o $newiso . || error_exit "Failed making iso"

