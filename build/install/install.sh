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
    rc=$?

    cd /tmp

    if [ -n "$TMP_HOSTMOUNT" ]; then
        if [ -d "$TMP_HOSTMOUNT" ]; then
            fusermount -u $TMP_HOSTMOUNT
            rmdir $TMP_HOSTMOUNT
        fi
    fi

    if [ -d "$TMP_OLDISO" ]; then
        fusermount -u $TMP_OLDISO
        rmdir $TMP_OLDISO
    fi

    if [ -f "$CONF" ]; then
        rm $CONF
    fi

    if [ -d "$TMP_ISOPUPPET" ]; then
        rm -Rf $TMP_ISOPUPPET
    fi
}

get_deb_name() {
    ar p $1 control.tar.gz | tar xzO ./control | grep "^Package:.* " | sed 's/.* //'
    if [ $PIPESTATUS -ne 0 ]; then
        echo "Error in get_deb_name($1)"
        exit 1
    fi
}

get_deb_rev() {
    ar p $1 control.tar.gz | tar xzO ./control | grep "^Version:.* " | sed 's/.* //'
    if [ $PIPESTATUS -ne 0 ]; then
        echo "Error in get_deb_rev($1)"
        exit 1
    fi
}


# Added logic for ".orig" files:
#   1. Is there an .orig file for the new file?
#   2. If the file is not present in base ISO -> Error!
#   3. If the file is changed i base ISO -> Error!  (need manual rebase)
#   4. If there is no .orig file, but file is present in base ISO: Error!
verify_orig_files() {
    OLDDIR=$1
    NEWDIR=$2

    pushd $NEWDIR >/dev/null
    for f in $(find * -type f -name '*.orig')
    do
        origfile=$NEWDIR/$f
        oldfile=$OLDDIR/$(echo $f | sed 's/.orig$//')
        newfile=$NEWDIR/$(echo $f | sed 's/.orig$//')

        origfile=${newfile}.orig
        # If no corresponding base file, error
        if [ ! -f $oldfile ]; then
            printf "\n\n\n\n"
            echo "Error: found ${newfile} but no"
            echo "Error: ${oldfile}"
            echo "Error: Manual rebase is needed!"
            printf "\n\n\n\n"
            exit 1
        fi

        # If orig file differs from base file, error
        if ! diff -q $origfile $oldfile > /dev/null; then
            printf "\n\n\n\n"
            echo "Error: $origfile differs from"
            echo "Error: $oldfile!"
            echo "Error: Manual rebase is needed!"
            printf "\n\n\n\n"
            exit 1
        fi

    done


    # Check that there we're not overwriting oldfiles without having a ".orig" copy
    for f in $(find * -type f ! -name '*.orig')
    do
        newfile=$NEWDIR/$(echo $f | sed 's/.orig$//')
        origfile=${newfile}.orig
        oldfile=$OLDDIR/$f
        if [ -f $oldfile ]; then
            if [ ! -f $origfile ]; then
                printf "\n\n\n\n"
                echo "Error: Will overwrite $oldfile, but there is no"
                echo "Error: $origfile!"
                echo "Error: You need to create the `basename $origfile`!"
                printf "\n\n\n\n"
                exit 1
            fi
        fi
    done


    popd >/dev/null
}

prep_make_live() {
    DEST=$TMP_HOSTMOUNT
    REPO=$DEST/var/www/nailgun/ubuntu/fuelweb/x86_64
    echo "Live install"
    ssh-copy-id root@$FUELHOST
    sshfs root@1${FUELHOST}:/ $TMP_HOSTMOUNT

    if [ -f  $REPO/dists/trusty/main/binary-amd64/Packages.backup ]; then
        echo "Error - found backup file for Packages!"
        exit 1
    fi

    if [ -f  $REPO/dists/trusty/main/binary-amd64/Packages.gz.backup ]; then
        echo "Error - found backup file for Packages.gz!"
        exit 1
    fi

    if [ -f  $REPO/dists/trusty/Release.backup ]; then
        echo "Error - found backup file for Release!"
        exit 1
    fi

    if [ -d  $DEST/etc/puppet.backup ]; then
        echo "Error - found backup file for Puppet!"
        exit 1
    fi

    cp $REPO/dists/trusty/main/binary-amd64/Packages $REPO/dists/trusty/main/binary-amd64/Packages.backup
    cp $REPO/dists/trusty/main/binary-amd64/Packages.gz $REPO/dists/trusty/main/binary-amd64/Packages.gz.backup
    cp $REPO/dists/trusty/Release $REPO/dists/trusty/Release.backup
    cp -Rvp $DEST/etc/puppet $DEST/etc/puppet.backup
}

post_make_live() {
    if [ -d $TOP/release/puppet/modules ]; then
        echo "Installing into Puppet:"
        cd $TOP/release/puppet/modules
        if [ `ls -1 | wc -l` -gt 0 ]; then
            for dir in *
            do
                echo "   $dir"
                cp -Rp $dir $DEST/etc/puppet/modules
            done
        fi
    fi
}

make_live() {
    prep_make_live
    copy_packages
    post_make_live
}


prep_make_iso() {
    DEST=$TOP/newiso
    REPO=$DEST/ubuntu
    echo "Preparing ISO..."
    echo "Unpack of old ISO..."
    if [ -d newiso ]; then
        chmod -R 755 newiso
        rm -rf newiso
    fi
    mkdir newiso
    fusermount -u $TMP_OLDISO 2>/dev/null || cat /dev/null
    fuseiso -p $ORIGISO $TMP_OLDISO
    sleep 1
    cd $TMP_OLDISO
    find . | cpio -pd $TOP/newiso
    cd ..
    fusermount -u $TMP_OLDISO
    rm -Rf $TMP_OLDISO
    chmod -R 755 $TOP/newiso
}

make_iso_image() {
    echo "Making ISO..."
    cd $DEST
    find . -name TRANS.TBL -exec rm {} \;
    rm -rf rr_moved

    if [[ -z "$OPNFV_GIT_SHA" ]]; then
        OPNFV_GIT_SHA=$(git rev-parse --verify HEAD)
    fi

    mkisofs --quiet -r -V "$VOLUMEID" -publisher "$PUBLISHER" \
        -p "$OPNFV_GIT_SHA" -J -R -b isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 -boot-info-table \
        --hide-rr-moved \
        --joliet-long \
        -x "lost+found" -o $NEWISO .

    isoinfo -d -i $NEWISO
}

# iso_copy_puppet: Create a new puppet-slave.tgz for the iso
iso_copy_puppet() {
    echo "Installing into Puppet..."
    mkdir -p $TMP_ISOPUPPET/release/puppet
    cd $TMP_ISOPUPPET/release/puppet
    tar xzf $DEST/puppet-slave.tgz
    cd $TOP/release/puppet/modules

    # Remove all .orig files before copying as they now have been verfied

    if [ -d $TOP/release/puppet/modules ]; then
        if [ `ls -1 | wc -l` -gt 0 ]; then
            verify_orig_files $TMP_ISOPUPPET/release/puppet $TOP/release/puppet/modules
            find $TOP/release/puppet/modules -type f -name '*.orig' -exec rm {} \;
            for dir in $TOP/release/puppet/modules/*
            do
                echo "   $dir"
                cp -Rp $dir $TMP_ISOPUPPET/release/puppet
            done
        fi
    fi

    cd $TMP_ISOPUPPET/release/puppet
    tar czf $DEST/puppet-slave.tgz .
    cd $TOP
    rm -Rf $TMP_ISOPUPPET
}

# iso_modify_image: Add/patch files in the ISO root
iso_modify_image () {
    # TODO: Add logic for ".orig" files (hey! make a function!), which would look
    # something like:
    #   1. Is there an .orig file?
    #   2. If the file is not present in origiso -> Error exit
    #   3. If the file is changed in origiso -> Error exit (need manual rebase)
    #   4. Otherwise continue, but don't copy orig file (or maybe we should?)
    # ... and corresponding reverse logic:
    #   1. If there is no .orig file, but file is present in origiso -> Error exit
    echo "Modify ISO files (wild copy)..."

    verify_orig_files $DEST $TOP/release/isoroot
    # Remove all .orig files before copying as they now have been verfied
    find $TOP/release/isoroot -type f -name '*.orig' -exec rm {} \;

    cd $TOP/release/isoroot
    cp -Rvp . $DEST

    # Add all Git info files
    sort $TOP/gitinfo*.txt > $DEST/gitinfo.txt
    cp $DEST/gitinfo.txt $REPORTFILE
}

make_iso() {
    prep_make_iso
    copy_packages
    #iso_copy_puppet
    iso_modify_image
    make_iso_image
}

copy_packages() {
    echo "Copying Debian packages..."
    cd $TOP/release/packages/ubuntu/pool/debian-installer

    for udeb in `ls -1 | grep '\.udeb$'`
    do
        echo "   $udeb"
        cp $udeb $REPO/pool/debian-installer
	echo "Did not expect a package here, not supported"
	exit 1
    done

    cd $TOP/release/packages/ubuntu/pool/main
    for deb in `ls -1 | grep '\.deb$'`
    do
        echo "   $deb"
        cp $deb $REPO/pool/main
	echo "Did not expect a package here, not supported"
	exit 1
    done

    echo "Running Fuel package patch file"
    pushd $REPO/pool/main > /dev/null

    for line in `cat $TOP/apply_patches | grep -v "^#" | grep -v "^$"`; do
        echo "Line is $line"
        echo "Did not expect a line here, not supported"
        exit 1
        ref=`echo $line | cut -d '>' -f 1`
        origpkg=`echo $line| cut -d '>' -f 2`
        url=`echo $line | cut -d '>' -f 3`

        if [ -z "$origpkg" ]; then
            echo "Error: No origpkg for patching"
            exit 1
        fi

        if [ -z "$url" ]; then
            echo "Error: No url for patching"
            exit 1
        fi

        if [ -z "$ref" ]; then
            echo "Error: No reference text for patching"
            exit 1
        fi

        echo "CM: Patching Fuel package for $ref" | tee -a $REPORTFILE
        echo "CM: Replacing package $origpkg with $url" | tee -a $REPORTFILE
        oldrev=`get_deb_rev $origpkg`
        rm $origpkg
        wget --quiet $url
        topkg=`basename $url`
        echo "CM: MD5 of new package:" | tee -a $REPORTFILE
        md5sum $topkg | tee -a $REPORTFILE

        patchname=`get_deb_name $topkg`
        patchrev=`get_deb_rev $topkg`
        echo "Correcting dependencies towards $patchname rev $patchrev - old rev $oldrev" | tee -a $REPORTFILE
        $TOP/patch-packages/tools/correct_deps $patchname $oldrev $patchrev | tee -a $REPORTFILE
        if [ $PIPESTATUS -ne 0 ]; then
            exit 1
        fi
    done

    printf "Done running Fuel patch file\n\n"
    echo "Running add packages file"
    for line in `cat $TOP/add_opnfv_packages | grep -v "^#" | grep -v "^$"`; do
        echo "Line is $line"
        echo "Did not expect a line here, not supported"
        exit 1
        ref=`echo $line | cut -d '>' -f 1`
        origpkg=`echo $line| cut -d '>' -f 2`
        url=`echo $line | cut -d '>' -f 3`

        if [ -z "$origpkg" ]; then
            echo "Error: No origpkg for patching"
            exit 1
        fi

        if [ -z "$url" ]; then
            echo "Error: No url for patching"
            exit 1
        fi

        if [ -z "$ref" ]; then
            echo "Error: No reference text for patching"
            exit 1
        fi

        if [ "$origpkg" != "NONE" ]; then
            echo "CM: Patching added package for $ref" | tee -a $REPORTFILE
            echo "CM: Replacing package $origpkg with $url" | tee -a $REPORTFILE
            oldrev=`get_deb_rev $origpkg`
            rm $origpkg
        else
            echo "CM: Adding previoulsy uninstalled package for $ref" tee -a $REPORTFILE
        fi
        wget --quiet $url
        topkg=`basename $url`
        echo "CM: MD5 of new package:" | tee -a $REPORTFILE
        md5sum $topkg | tee -a $REPORTFILE
        if [ "$origpkg" != "NONE" ]; then
            patchname=`get_deb_name $topkg`
            patchrev=`get_deb_rev $topkg`
            echo "Correcting dependencies towards $patchname rev $patchrev - old rev $oldrev" | tee -a $REPORTFILE
            $TOP/patch-packages/tools/correct_deps $patchname $oldrev $patchrev | tee -a $REPORTFILE
            if [ $PIPESTATUS -ne 0 ]; then
                exit 1
            fi
        fi
    done
    printf "Done running add packages file\n\n"

    popd > /dev/null

    if [ -f $TOP/patch-packages/release/patch-replacements ]; then
        echo "Applying package patches" | tee -a $REPORTFILE
        pushd $REPO/pool/main > /dev/null
	echo "CM: I am now in $(pwd)"
        printf "\n\n" | tee -a  $REPORTFILE
        for line in `cat $TOP/patch-packages/release/patch-replacements`
        do
            echo "Processing $line ..."
            frompkg=`echo $line | cut -d ">" -f 1`
            topkg=`echo $line | cut -d ">" -f 2`
            echo "CM: Applying patch to $frompkg" | tee -a $REPORTFILE
            echo "CM: New package rev after patch: $topkg" | tee -a $REPORTFILE

            if [ ! -f $frompkg ]; then
                echo "Error: Can't find $frompkg in repo"
                exit 1
            else
                oldrev=`get_deb_rev $frompkg`
                echo "Removing $frompkg from repo"
                rm $frompkg
            fi

            if [ ! -f $TOP/patch-packages/release/packages/$topkg ]; then
                echo "Error: Can't find $topkg in patch release"
                exit 1
            else
                echo "Adding $topkg to repo"
                pkg_dest=$(dirname $frompkg)
                cp $TOP/patch-packages/release/packages/$topkg $pkg_dest/
            fi

            pushd $pkg_dest > /dev/null
            patchname=`get_deb_name $topkg`
            patchrev=`get_deb_rev $topkg`
            echo "Correcting dependencies towards $patchname rev $patchrev - old rev $oldrev" | tee -a $REPORTFILE
            $TOP/patch-packages/tools/correct_deps $patchname $oldrev $patchrev | tee -a $REPORTFILE
            if [ $PIPESTATUS -ne 0 ]; then
                exit 1
            fi
            popd > /dev/null
        done
        popd > /dev/null
    fi

    echo "Generating metadata..."
    pushd $REPO > /dev/null

    # The below methods are from 15B
    APT_REL_CONF="$TOP/install/apt-ftparchive-release.conf"
    APT_DEB_CONF="$TOP/install/apt-ftparchive-deb.conf"
    APT_UDEB_CONF="$TOP/install/apt-ftparchive-udeb.conf"

    apt-ftparchive -c "${APT_REL_CONF}" generate "${APT_DEB_CONF}"
    echo Not running apt-ftparchive generate "${APT_UDEB_CONF}"

    # Fuel also needs this index file
    # cat dists/trusty/main/binary-amd64/Packages | \
    #    awk '/^Package:/{pkg=$2}
    # /^Version:/{print pkg ": \"" $2 "\""}' > ubuntu-versions.yaml
    # cp ubuntu-versions.yaml $DEST

    apt-ftparchive -c "${APT_REL_CONF}" release dists/mos10.0/ > dists/mos10.0/Release
    gzip -9cf dists/mos10.0/Release > dists/mos10.0/Release.gz

    popd > /dev/null

}


#############################################################################

trap my_exit EXIT

CONF=`mktemp /tmp/XXXXXXX`
MODE=$1
TOP=`pwd`

if [ $MODE = "iso" ]; then
    PUBLISHER="OPNFV"
    TMP_OLDISO=`mktemp -d /tmp/XXXXXXX`
    TMP_ISOPUPPET=`mktemp -d /tmp/XXXXXXX`
    ORIGISO=$2
    NEWISO=$3
    VOLUMEID="$4_$5"
    REPORTFILE="${NEWISO}.txt"
    echo "Opening reportfile at $REPORTFILE"
    touch $REPORTFILE
    if [ ! -f $ORIGISO ]; then
        echo "Can't find original iso at $ORIGISO"
        rm $CONF
        exit 1
    fi

    make_iso
else
    echo "Unknown mode: $MODE"
    exit 1
fi
