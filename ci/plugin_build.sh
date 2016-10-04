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
`basename $0`: Builds Fuel@OPNFV plugins

usage: `basename $0` -r plugin-repo [-l log-file] [-b plugin-branch] [-c Plugin-commit] [-v ci-defined-revision] [-m ci-build-metadata] [-f flags] [output-directory]

OPTIONS:
  -l log-file
       specifies the output log-file (stdout and stderr), if not specified
       logs are output to console as normal
  -v version tag to be applied to the build result
  -f flag[...]
       build flags:
          s: Do nothing, succeed
          f: Do nothing, fail
          D: Debug mode
  -m JSON formatted CI Metada
  -r Plugin repo URI
  -b Plugin repo branch
  -c Plugin repo commit/ref spec
  -h help, prints this help text

  output-directory, specifies the directory for the output artifacts
  (.tar file). If no output-directory is specified, the current path
  when calling the script is used.


Description:

build_plugin.sh builds Fuel@opnfv plugin artifacts.

Logging is by default to console, but can be directed elsewhere with the -l
option in which case both stdout and stderr is redirected to that destination.

Return codes:
 - 0 Success!
 - 1-99 Unspecified build error
 - 100-199 Build system internal error (not build it self)
     - 101 Build system instance busy
 - 200 Build failure

Examples:
   plugin_build.sh -r https://github.com/openstack/fuel-plugin-bgpvpn.git -b master -c 3349842af5724be63a74a82c9060848d9d3d299e -v R1A02 -m '{"Jenkins-build-job-id":"1234","jenkins-build-url":http://jenkins.opnfv.org/1234}' -l ~/mylog.log ~/my_plugin_artifact_dir

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
BUILD_BASE=$(readlink -e ${SCRIPT_DIR}/../build/f_plugin-build)
RESULT_DIR="${BUILD_BASE}/release"

#
# END of variables to customize
############################################################################

############################################################################
# BEGIN of script assigned default variables
#
MAKE_ARGS=""
REPO_PROVIDED=0
#
# END of script assigned variables
############################################################################

build() {
    echo "CI build parameters:"
    echo "SCRIPT_DIR = $SCRIPT_DIR"
    echo "BUILD_BASE = $BUILD_BASE"
    echo "RESULT_DIR = $RESULT_DIR"
    echo "DEBUG = $DEBUG"
    echo "OUTPUT_DIR = $OUTPUT_DIR"
    echo "BUILD_LOG = $BUILD_LOG"
    echo "MAKE_ARGS = $MAKE_ARGS"

    cd ${BUILD_BASE}
    if make ${MAKE_ARGS} all; then
        echo "Copying build result into $OUTPUT_DIR"
        cp ${RESULT_DIR}/*.tar.gz ${OUTPUT_DIR}
        cp ${RESULT_DIR}/metadata.yaml ${OUTPUT_DIR}
    else
        error_exit "Build failed"
    fi
}

############################################################################
# BEGIN of main
#
while getopts "l:v:m:r:b:c:f:h" OPTION
do
    case $OPTION in
        l)
            BUILD_LOG=$(readlink -f ${OPTARG})
            ;;
        v)
            MAKE_ARGS+="REVSTATE=${OPTARG}; "
            ;;
        m)
            MAKE_ARGS+="CI_META=${OPTARG}; "
            ;;

        r)
            MAKE_ARGS+="PLUGIN_REPO=${OPTARG}"
            REPO_PROVIDED=1
            ;;

        b)
            MAKE_ARGS+="PLUGIN_BRANCH=${OPTARG}; "
            ;;

        c)
            MAKE_ARGS+="PLUGIN_CHANGE=${OPTARG};"
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

if [ $REPO_PROVIDED -eq 0 ]; then
    error_exit "No Plugin repository or branch provided"
fi

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
