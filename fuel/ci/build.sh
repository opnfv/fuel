#!/bin/bash
set -e
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

trap 'echo "Exiting ..."; \
if [ -f ${LOCK_FILE} ]; then \
   if [ $(cat ${LOCK_FILE}) -eq $$ ]; then \
      rm -f ${LOCK_FILE}; \
   fi; \
fi;' EXIT

############################################################################
# BEGIN of usage description
#
usage ()
{
cat << EOF
$0 Builds the Fuel@OPNFV stack

usage: $0 [-s spec-file] [-c cache-URI] [-l log-file] [-f Flags] build-directory

OPTIONS:
  -s spec-file ($BUILD_SPEC), define the build-spec file, default ../build/config.mk
  -c cache base URI ($BUILD_CACHE_URI), specifies the base URI to a build cache to be used/updated - the name is automatically generated from the md5sum of the spec-file, http://, ftp://, file://[absolute path] suported.

  -l log-file ($BUILD_LOG), specifies the output log-file (stdout and stderr), if not specified logs are output to console as normal
  -v version tag to be applied to the build result
  -r alternative remote access method script/program. curl is default.
  -t run small build-script unit test.
  -T run large build-script unit test.
  -f build flags ($BUILD_FLAGS):
     o s: Do nothing, succeed
     o f: Do nothing, fail
     o t: run build unit tests
     o i: run interactive (-t flag to docker run)
     o P: Populate a new local cache and push it to the (-c cache-URI) cache artifactory if -c option is present, currently file://, http:// and ftp:// are supported
     o d: Detatch - NOT YET SUPPORTED

  build-directory ($BUILD_DIR), specifies the directory for the output artifacts (.iso file).

  -h help, prints this help text

Description:
build.sh builds opnfv .iso artifact.
To reduce build time it uses build cache on a local or remote location. The cache is rebuilt and uploaded if either of the below conditions are met:
1) The P(opulate) flag is set and the -c cache-base-URI is provided, if -c is not provided the cache will stay local.
2) If the cache is invalidated by one of the following conditions:
   - The config spec md5sum does not compare to the md5sum for the spec which the cache was built.
   - The git Commit-Id on the remote repos/HEAD defined in the spec file does not correspont with the Commit-Id for what the cache was built with.
3) A valid cache does not exist on the specified -c cache-base-URI.

The cache URI object name is fuel_cache-"md5sum(spec file)"

Logging by default to console, but can be directed elsewhere with the -l option in which case both stdout and stderr is redirected to that destination.

Built in unit testing of components is enabled by adding the t(est) flag.

Return codes:
 - 0 Success!
 - 1-99 Unspecified build error
 - 100-199 Build system internal error (not build it self)
   o 101 Build system instance busy
 - 200 Build failure

Examples:
build -c http://opnfv.org/artifactory/fuel/cache -d ~/jenkins/genesis/fuel/ci/output -f ti
NOTE: At current the build scope is set to the git root of the repository, -d destination locations outside that scope will not work
EOF
}
#
# END of usage description
############################################################################

############################################################################
# Begin of string xor function
#
function  xor()
{
      local res=(`echo "$1" | sed "s/../0x& /g"`)
      shift 1
      while [[ "$1" ]]; do
            local one=(`echo "$1" | sed "s/../0x& /g"`)
            local count1=${#res[@]}
            if [ $count1 -lt ${#one[@]} ]
            then
                  count1=${#one[@]}
            fi
            for (( i = 0; i < $count1; i++ ))
            do
                  res[$i]=$((${one[$i]:-0} ^ ${res[$i]:-0}))
            done
            shift 1
      done
       printf "%02x" "${res[@]}"
}
#
# END of string xor function
############################################################################

############################################################################
# BEGIN of variables to customize
#
BUILD_BASE=$(readlink -e ../build/)
RESULT_DIR="${BUILD_BASE}/release"
BUILD_SPEC="${BUILD_BASE}/config.mk"
CACHE_DIR="cache"
LOCAL_CACHE_ARCH_NAME="fuel-cache"

REMOTE_ACCESS_METHD=curl
INCLUDE_DIR=../include
#
# END of variables to customize
############################################################################

############################################################################
# BEGIN of script assigned variables
#
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
LOCK_FILE="${SCRIPT_DIR}/.build.lck"
CACHE_TMP="${SCRIPT_DIR}/tmp"
TEST_SUCCEED=0
TEST_FAIL=0
UNIT_TEST=0
UPDATE_CACHE=0
POPULATE_CACHE=0
RECURSIVE=0
DETACH=0
DEBUG=0
INTEGRATION_TEST=0
FULL_INTEGRATION_TEST=0
INTERACTIVE=0
BUILD_CACHE_URI=
BUILD_SPEC=
BUILD_DIR=
BUILD_LOG=
BUILD_VERSION=
MAKE_ARGS=
FUEL_GIT_SRC="$(make -f ../build/config.mk get-fuel-repo | cut -d " " -f1)"
FUEL_GIT_BRANCH="$(make -f ../build/config.mk get-fuel-repo | cut -d " " -f2)"
CACHE_MD5=$(md5sum ../build/cache.mk | cut -f1 -d " ")
CONFIG_MD5=$(md5sum ../build/config.mk | cut -f1 -d " ")
FUEL_COMMIT_ID=$(git ls-remote $FUEL_GIT_SRC -t $FUEL_GIT_BRANCH | cut -d $'\t' -f1)
REMOTE_CACHE_ARCH_HASH_TMP="$(xor $CACHE_MD5 $CONFIG_MD5)"
REMOTE_CACHE_ARCH_HASH="$(xor $REMOTE_CACHE_ARCH_HASH_TMP $FUEL_COMMIT_ID)"
REMOTE_CACHE_ARCH_NAME="fuel_cache-$REMOTE_CACHE_ARCH_HASH"
#
# END of script assigned variables
############################################################################

############################################################################
# BEGIN of include pragmas
#
source ${INCLUDE_DIR}/build.sh.debug
#
# END of include
############################################################################

############################################################################
# BEGIN of main
#
while getopts "s:c:v:f:l:r:RtTh" OPTION
do
    case $OPTION in
        h)
            usage
            rc=0
            exit $rc
            ;;

        s)
            BUILD_SPEC=${OPTARG}
            ;;

        c)
            BUILD_CACHE_URI=${OPTARG}
            ;;

        l)
            BUILD_LOG=${OPTARG}
            ;;

        v)
            BUILD_VERSION=${OPTARG}
            ;;

        f)
            BUILD_FLAGS=${OPTARG}
            ;;

        r)  REMOTE_ACCESS_METHD=${OPTARG}
            ;;

        R)
            RECURSIVE=1
            ;;

        t)
            INTEGRATION_TEST=1
            ;;

        T)
            INTEGRATION_TEST=1
            FULL_INTEGRATION_TEST=1
            ;;

        *)
            echo "${OPTION} is not a valid argument"
            rc=100
            exit $rc
            ;;
    esac
done

if [ -z $BUILD_DIR ]; then
    BUILD_DIR=$(echo $@ | cut -d ' ' -f ${OPTIND})
fi

for ((i=0; i<${#BUILD_FLAGS};i++)); do
    case ${BUILD_FLAGS:$i:1} in
        s)
            rc=0
            exit $rc
            ;;

        f)
            rc=1
            exit $rc
            ;;

        t)
            UNIT_TEST=1
            ;;

        i)
            INTERACTIVE=1
            ;;

        P)
            POPULATE_CACHE=1
            ;;

        d)
            DETACH=1
            echo "Detach is not yet supported - exiting ...."
            rc=100
            exit $rc
            ;;

        D)
            DEBUG=1
            ;;

        *)
            echo "${BUILD_FLAGS:$i:1} is not a valid build flag - exiting ...."
            rc=100
            exit $rc
            ;;
    esac
done

if [ ${INTEGRATION_TEST} -eq 1 ]; then
    integration-test
    rc=0
    exit $rc
fi

if [ ! -f ${BUILD_SPEC} ]; then
    echo "spec file does not exist: $BUILD_SPEC - exiting ...."
    rc=100
    exit $rc
fi

if [ -z ${BUILD_DIR} ]; then
    echo "Missing build directory - exiting ...."
    rc=100
    exit $rc
fi

if [ ! -z ${BUILD_LOG} ]; then
    if [[ ${RECURSIVE} -ne 1 ]]; then
        set +e
        eval $0 -R $@ > ${BUILD_LOG} 2>&1
        rc=$?
        set -e
        if [ $rc -ne 0]; then
            exit $rc
        fi
    fi
fi

if [ ${TEST_SUCCEED} -eq 1 ]; then
    sleep 1
    rc=0
    exit $rc
fi

if [ ${TEST_FAIL} -eq 1 ]; then
    sleep 1
    rc=1
    exit $rc
fi

if [ -e ${LOCK_FILE} ]; then
    echo "A build job is already running, exiting....."
    rc=101
    exit $rc
fi

echo $$ > ${LOCK_FILE}

if [ ! -z ${BUILD_CACHE_URI} ]; then
    if [ ${POPULATE_CACHE} -ne 1 ]; then
        rm -rf ${CACHE_TMP}/cache
        mkdir -p ${CACHE_TMP}/cache
        echo "Downloading cache archive ${BUILD_CACHE_URI}/${REMOTE_CACHE_ARCH_NAME} ..."
        set +e
        ${REMOTE_ACCESS_METHD} -o ${CACHE_TMP}/cache/${LOCAL_CACHE_ARCH_NAME}.tgz ${BUILD_CACHE_URI}/${REMOTE_CACHE_ARCH_NAME}.tgz
        rc=$?
        set -e
        if [ $rc -ne 0 ]; then
            echo "Remote cache does not exist, or is not accessible - a new cache will be built ..."
            POPULATE_CACHE=1
        else
            echo "Unpacking cache archive ..."
            set +e
            tar -C ${CACHE_TMP}/cache -xvf ${CACHE_TMP}/cache/${LOCAL_CACHE_ARCH_NAME}.tgz
            rc=$?
            set -e
            if [ $rc -ne 0 ]; then
                echo "WARNING: The cache seems to be corrupt or has trailing garbage, will try to use brute force"
                echo "Info about the cache below:"
                set +e
                file ${CACHE_TMP}/cache/${LOCAL_CACHE_ARCH_NAME}.tgz
                tar -C ${CACHE_TMP}/cache -tvf ${CACHE_TMP}/cache/${LOCAL_CACHE_ARCH_NAME}.tgz
                set -e
                echo "Current time is: `date`"
                set +e
                pushd ${CACHE_TMP}/cache
                gunzip -dcq ${CACHE_TMP}/cache/${LOCAL_CACHE_ARCH_NAME}.tgz | tar -xvf -
                rc=$?
                set -e
                popd
                if [ $rc -ne 0 ]; then
                    echo "ERROR: Not able to resolve the cache corruption"
                    POPULATE_CACHE=1
                else
                    echo "The chache corruption was resolved"
                    cp ${CACHE_TMP}/cache/cache/.versions ${BUILD_BASE}/.
                    set +e
                    make -C ${BUILD_BASE} validate-cache;
                    rc=$?
                    set -e
                    if [ $rc -ne 0 ]; then
                        echo "Cache invalid - a new cache will be built "
                        POPULATE_CACHE=1
                    else
                        echo "Cache is up to date and will be used"
                        cp -rf ${CACHE_TMP}/cache/cache/. ${BUILD_BASE}
                    fi
                fi
            else
                echo "Cache archive is intact"
                cp ${CACHE_TMP}/cache/cache/.versions ${BUILD_BASE}/.
                set +e
                make -C ${BUILD_BASE} validate-cache;
                rc=$?
                set -e

                if [ $rc -ne 0 ]; then
                    echo "Cache invalid - a new cache will be built "
                    POPULATE_CACHE=1
                else
                    echo "Cache is up to date and will be used"
                    cp -rf ${CACHE_TMP}/cache/cache/. ${BUILD_BASE}
                fi
            fi
            rm -rf ${CACHE_TMP}/cache
        fi
    fi
fi

if [ ${POPULATE_CACHE} -eq 1 ]; then
    if [ ${DEBUG} -eq 0 ]; then
        set +e
        cd ${BUILD_BASE} && make clean
        rc=$?
        set -e
        if [ $rc -ne 0 ]; then
            echo "Build - make clean failed, exiting ..."
            rc=100
            exit $rc
        fi
    fi
fi

if [ ! -z ${BUILD_VERSION} ]; then
    MAKE_ARGS+="REVSTATE=${BUILD_VERSION} "
fi

if [ ${UNIT_TEST} -eq 1 ]; then
    MAKE_ARGS+="UNIT_TEST=TRUE "
else
    MAKE_ARGS+="UNIT_TEST=FALSE "
fi

if [ ${INTERACTIVE} -eq 1 ]; then
    MAKE_ARGS+="INTERACTIVE=TRUE "
else
    MAKE_ARGS+="INTERACTIVE=FALSE "
fi

MAKE_ARGS+=all

if [ ${DEBUG} -eq 0 ]; then
    set +e
    cd ${BUILD_BASE} && make ${MAKE_ARGS}
    rc=$?
    set -e
    if [ $rc -gt 0 ]; then
        echo "Build: make all failed, exiting ..."
        rc=200
        exit $rc
    fi
else
    debug_make
fi
set +e
make -C ${BUILD_BASE} prepare-cache
rc=$?
set -e

if [ $rc -gt 0 ]; then
    echo "Build: make prepare-cache failed - exiting ..."
    rc=100
    exit $rc
fi
echo "Copying built OPNFV .iso file to target directory ${BUILD_DIR} ..."
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cp ${BUILD_BASE}/.versions ${BUILD_DIR}
cp ${RESULT_DIR}/*.iso* ${BUILD_DIR}

if [ $POPULATE_CACHE -eq 1 ]; then
    if [ ! -z ${BUILD_CACHE_URI} ]; then
        echo "Building cache ..."
        tar --dereference -C ${BUILD_BASE} -caf ${BUILD_BASE}/${LOCAL_CACHE_ARCH_NAME}.tgz ${CACHE_DIR}
        set +e
        tar -C ${CACHE_TMP}/cache -tvf ${BUILD_BASE}/${LOCAL_CACHE_ARCH_NAME}.tgz
        rc=$?
        set -e
        if [ $rc -ne 0 ]; then
            echo "WARNING the cache archive generated seems to be corrupt, or containing trailing garbage"
        else
            echo "The Cache archive build is intact"
        fi
        echo "Uploading cache ${BUILD_CACHE_URI}/${REMOTE_CACHE_ARCH_NAME}"
        ${REMOTE_ACCESS_METHD} -T ${BUILD_BASE}/${LOCAL_CACHE_ARCH_NAME}.tgz ${BUILD_CACHE_URI}/${REMOTE_CACHE_ARCH_NAME}.tgz
        rm ${BUILD_BASE}/${LOCAL_CACHE_ARCH_NAME}.tgz
    fi
fi
echo "Success!!!"
exit 0
#
# END of main
############################################################################
