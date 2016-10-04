#!/bin/bash
##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# jonas.bjurel@ericsson.com
# stefan.k.berg@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

GIT_INVOKE_PATH = $PWD
PLUGIN_BUILD_PATH ?= $(dirname `which $0`)
GIT_METADATA_FILE ?= ${PLUGIN_BUILD_PATH}/metadata.yaml


function log {
#    Needs work to be transparent and logged to metadata
#    echo "logging $@"
}

function write_meta_data {
    python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Repos\":\{\"${ORIGIN_REPO}\":\{\"Branch\":\"${BRANCH}\"\}\}\}
    python ${PLUGIN_BUILD_PATH}/yaml-parse.py -f $GIT_METADATA_FILE -w \{\"Repos\":\{\"${ORIGIN_REPO}\":\{\"Commit\":\"${COMMIT}\"\}\}\}
}

function get_repo_info {
    case "$1" in
        clone )
            shift
            while true; do
                case "$1" in
                    -v | --verbose ) shift ;;
                    -q | --quiet ) shift ;;
                    --process ) shift ;;
                    -n | no-checkout ) shift ;;
                    --bare ) shift ;;
                    --mirror ) shift ;;
                    -l | --local ) shift ;;
                    --no-hardlinks ) shift ;;
                    -s | --shared ) shift ;;
                    --recursive | --recursive-submodules ) shift ;;
                    --template ) shift 2 ;;
                    --reference ) shift 2 ;;
                    -o | --origin ) shift 2 ;;
                    -b | --branch )  shift 2 ;;
                    -u | --upload-pack ) shift 2;;
                    --depth ) shift 2;;
                    --single-branch ) shift ;;
                    --separate-git-dir ) shift 2 ;;
                    -c | --config ) shift 2 ;;
                    -- ) shift; break ;;
                    * ) break ;;
                esac
            done
            ORIGIN_REPO=$1
            if [ -z $2 ]; then
                REPO_PATH="${GIT_INVOKE_PATH}/${ORIGIN_REPO##*/}"
            else
                REPO_PATH=$2
            fi
            pushd $REPO_PATH &> /dev/null
            BRANCH=$(/usr/bin/git branch | grep "*" | cut -d " " -f2)
            COMMIT=$(/usr/bin/git show-ref --head | head -n1 | cut -d " " -f1)
            popd &>1 /dev/null
            ;;
    checkout | reset )
            shift
            ORIGIN_REPO=$(/usr/bin/git remote show origin | grep "Fetch URL:" | cut -d " " -f5)
            REPO_PATH=$GIT_INVOKE_PATH;
            BRANCH=$(/usr/bin/git branch | grep "*" | cut -d " " -f2)
            COMMIT=$(/usr/bin/git show-ref --head | head -n1 | cut -d " " -f1)
            ;;
        * )
            exit 0
    esac
}

GIT_OUTPUT=$(/usr/bin/git $@ 2>&1)
GIT_RESULT=$?
echo "$GIT_OUTPUT"
log "git $@ : $GIT_OUTPUT"
if [ $GIT_RESULT -ne 0 ]; then
    exit $GIT_RESULT
fi
get_repo_info $@
write_meta_data
exit 0
