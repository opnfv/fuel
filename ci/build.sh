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

############################################################################
# BEGIN of usage description
#
usage ()
{
cat | more << EOF
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
`basename $0`: Builds the Fuel@OPNFV stack

usage: `basename $0` [-s spec-file] [-c cache-URI] [-l log-file] [-f flags]
       [output-directory]

OPTIONS:
  -s spec-file (NOTE! DEPRECATED!)
      define the build-spec file, default ../build/config.mk. The script only
      verifies that the spec-file exists.
  -c cache base URI
       specifies the base URI to a build cache to be used/updated, supported
       methods are http://, ftp:// and file://
  -l log-file
       specifies the output log-file (stdout and stderr), if not specified
       logs are output to console as normal
  -v
       version tag to be applied to the build result
  -r
       alternative remote access method script/program. curl is default.
  -f flag[...]
       build flags:
          s: Do nothing, succeed
          f: Do nothing, fail
          D: Debug mode
          P: Clear the local cache before building. This flag is only
             valid if the "-c cache-URI" options has been specified and
             and the  method in the cache-URI is file:// (local cache).

  -h help, prints this help text

  output-directory, specifies the directory for the output artifacts
  (.iso file). If no output-directory is specified, the current path
  when calling the script is used.


Description:

build.sh builds the opnfv .iso artifact.
To reduce build time it uses build caches on a local or remote location. A
cache is rebuilt and uploaded if either of the below conditions are met:
1) The P(opulate) flag is set and the -c cache-base-URI is provided and set
   to the method file:// , if -c is
   not provided the cache will stay local.
2) If a cache is invalidated by the make system - the exact logic is encoded
   in the cache.mk of the different parts of the build.
3) A valid cache does not exist on the specified -c cache-base-URI.

A cache has a blob (binary data) and a meta file in the format of:
   <SHA1>.blob
   <SHA1>.meta

Logging is by default to console, but can be directed elsewhere with the -l
option in which case both stdout and stderr is redirected to that destination.

Built in unit testing of components is enabled by adding the t(est) flag.

Return codes:
 - 0 Success!
 - 1-99 Unspecified build error
 - 100-199 Build system internal error (not build it self)
     - 101 Build system instance busy
 - 200 Build failure

Examples:
  build -c http://opnfv.org/artifactory/fuel/cache \
        -d ~/jenkins/genesis/fuel/ci/output -f ti

NOTE: At current the build scope is set to the git root of the repository, -d
      destination locations outside that scope will not work!
EOF
}
#
# END of usage description
############################################################################

############################################################################
# BEGIN of function error_exit

error_exit() {
    echo "$@" >&2
    exit 1
}

#
# END of function error_exit
############################################################################


############################################################################
# BEGIN of shorthand variables for internal use
#
SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
BUILD_BASE=$(readlink -e ${SCRIPT_DIR}/../build/)
RESULT_DIR="${BUILD_BASE}/release"
BUILD_SPEC="${BUILD_BASE}/config.mk"
LOCAL_CACHE_ARCH_NAME="${LOCAL_CACHE_ARCH_NAME:-fuel-cache}"

#
# END of variables to customize
############################################################################

############################################################################
# BEGIN of script assigned default variables
#
export CACHEBASE="file://$HOME/cache"
export CACHETRANSPORT="curl --silent"
CLEAR_CACHE=0
MAKE_ARGS=""

#
# END of script assigned variables
############################################################################

build() {
    echo "CI build parameters:"
    echo "SCRIPT_DIR = $SCRIPT_DIR"
    echo "BUILD_BASE = $BUILD_BASE"
    echo "RESULT_DIR = $RESULT_DIR"
    echo "BUILD_SPEC = $BUILD_SPEC"
    echo "LOCAL_CACHE_ARCH_NAME = $LOCAL_CACHE_ARCH_NAME"
    echo "CLEAR_CACHE = $CLEAR_CACHE"
    echo "DEBUG = $DEBUG"
    echo "OUTPUT_DIR = $OUTPUT_DIR"
    echo "BUILD_LOG = $BUILD_LOG"
    echo "MAKE_ARGS = $MAKE_ARGS"
    echo "CACHEBASE = $CACHEBASE"
    echo "CACHETRANSPORT = $CACHETRANSPORT"


    if [ "$CLEAR_CACHE" -eq 1 ]; then
        echo $CACHEBASE | grep -q '^file://' $CACHE_BASE
        if [ $? -ne 0 ]; then
            error_exit "Can't clear a non-local cache!"
        else
            CACHEDIR=$(echo $CACHEBASE | sed 's;file://;;')
            echo "Clearing local cache at $CACHEDIR..."
            rm -rvf $CACHEDIR/*
        fi
    fi

    echo make ${MAKE_ARGS} cache

    cd ${BUILD_BASE}
    if make ${MAKE_ARGS} cache; then
        echo "Copying build result into $OUTPUT_DIR"
        sort ${BUILD_BASE}/gitinfo*.txt > ${OUTPUT_DIR}/gitinfo.txt
        cp ${RESULT_DIR}/*.iso ${OUTPUT_DIR}
        cp ${RESULT_DIR}/*.iso.txt ${OUTPUT_DIR}
    else
        error_exit "Build failed"
    fi
}

############################################################################
# BEGIN of main
#

############################################################################
# Disable iso build for Fuel engine
exit 0
############################################################################

while getopts "s:c:l:v:f:r:f:h" OPTION
do
    case $OPTION in
        s)
            BUILD_SPEC=${OPTARG}
            if [ ! -f ${BUILD_SPEC} ]; then
                echo "spec file does not exist: $BUILD_SPEC - exiting ...."
                exit 100
            fi
            ;;
        c)
            # This value is used by cache.sh
            export CACHEBASE=${OPTARG}
            ;;
        l)
            BUILD_LOG=$(readlink -f ${OPTARG})
            ;;
        v)
            MAKE_ARGS+="REVSTATE=${OPTARG}"
            ;;
        r)
            # This value is used by cache.sh
            export CACHETRANSPORT=${OPTARG}
            ;;
        h)
            usage
            rc=0
            exit $rc
            ;;
        f)
            BUILD_FLAGS=${OPTARG}
            for ((i=0; i<${#BUILD_FLAGS};i++)); do
                case ${BUILD_FLAGS:$i:1} in
                    s)
                        exit 0
                        ;;

                    f)
                        exit 1
                        ;;

                    P)
                        CLEAR_CACHE=1
                        ;;

                    D)
                        DEBUG=1
                        ;;

                    *)
                        error_exit "${BUILD_FLAGS:$i:1} is not a valid build flag - exiting ...."
                        ;;
                esac
            done
            ;;

        *)
            echo "${OPTION} is not a valid argument"
            rc=100
            exit $rc
            ;;
    esac
done

# Get output directory
shift $[$OPTIND - 1]
case $# in
    0)
        # No directory on command line
        OUTPUT_DIR=$(pwd)
        ;;
    1)
        # Directory on command line
        OUTPUT_DIR=$(readlink -f $1)
        ;;
    *)
        error_exit "Too many arguments"
        ;;
esac
mkdir -p $OUTPUT_DIR || error_exit "Could not access output directory $OUTPUT_DIR"


if [ -n "${BUILD_LOG}" ]; then
    touch ${BUILD_LOG} || error_exit "Could not write to log file ${BUILD_LOG}"
    build 2>&1 | tee ${BUILD_LOG}
else
    build
fi

rc=$?
exit $rc

#
# END of main
############################################################################
