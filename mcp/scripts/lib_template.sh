#!/bin/bash -e
# shellcheck disable=SC2155,SC1001,SC2015,SC2128
##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
# Library of shell functions dedicated to j2 template handling
#

PHAROS_GEN_CFG='./pharos/config/utils/generate_config.py'
PHAROS_IA='./pharos/config/installers/fuel/pod_config.yml.j2'
PHAROS_VALIDATE_SCHEMA_SCRIPT='./pharos/config/utils/validate_schema.py'
PHAROS_SCHEMA_PDF='./pharos/config/pdf/pod1.schema.yaml'
PHAROS_SCHEMA_IDF='./pharos/config/pdf/idf-pod1.schema.yaml'

# Handles pod_config and scenarios only
function do_templates_scenario {
  local image_dir=$1; shift
  local target_lab=$1; shift
  local target_pod=$1; shift
  local lab_config_uri=$1; shift
  local scenario_dir=$1; shift
  local extra_yaml=("$@")

  BASE_CONFIG_PDF="${lab_config_uri}/labs/${target_lab}/${target_pod}.yaml"
  BASE_CONFIG_IDF="${lab_config_uri}/labs/${target_lab}/idf-${target_pod}.yaml"
  LOCAL_PDF="${image_dir}/$(basename "${BASE_CONFIG_PDF}")"
  LOCAL_IDF="${image_dir}/$(basename "${BASE_CONFIG_IDF}")"

  # Expand scenario file and main reclass input (pod_config.yaml) based on PDF
  if ! curl --create-dirs -o "${LOCAL_PDF}" "${BASE_CONFIG_PDF}"; then
    notify_e "[ERROR] Could not retrieve PDF (Pod Descriptor File)!"
  elif ! curl -o "${LOCAL_IDF}" "${BASE_CONFIG_IDF}"; then
    notify_e "[ERROR] Could not retrieve IDF (Installer Descriptor File)!"
  fi
  # Check first if configuration files are valid
  if [[ ! "$target_pod" =~ "virtual" ]]; then
    if ! "${PHAROS_VALIDATE_SCHEMA_SCRIPT}" -y "${LOCAL_PDF}" \
      -s "${PHAROS_SCHEMA_PDF}"; then
      notify_e "[ERROR] PDF does not match yaml schema!"
    elif ! "${PHAROS_VALIDATE_SCHEMA_SCRIPT}" -y "${LOCAL_IDF}" \
      -s "${PHAROS_SCHEMA_IDF}"; then
      notify_e "[ERROR] IDF does not match yaml schema!"
    fi
  fi
  printenv | \
    awk '/^(SALT|MCP|MAAS).*=/ { gsub(/=/,": "); print }' >> "${LOCAL_PDF}"
  j2args=$(find "${scenario_dir}" -name '*.j2' -exec echo -j {} \;)
  # shellcheck disable=SC2086
  if ! python3 "${PHAROS_GEN_CFG}" -y "${LOCAL_PDF}" ${j2args} -b -v \
    -i "$(dirname "$(readlink -f "${PHAROS_IA}")")"; then
    notify_e '[ERROR] Could not convert j2 scenario definitions!'
  fi
  for _yaml in "${extra_yaml[@]}"; do
    awk '/^---$/{f=1;next;}f' "${_yaml}" >> "${LOCAL_PDF}"
  done
  if ! python3 "${PHAROS_GEN_CFG}" -y "${LOCAL_PDF}" \
    -i "$(dirname "$(readlink -f "${PHAROS_IA}")")" \
    -j "${PHAROS_IA}" -v > "${image_dir}/pod_config.yml"; then
    notify_e "[ERROR] Could not convert PDF+IDF to reclass model input!"
  fi
}

# Expand reclass and virsh network templates based on PDF + IDF + others
function do_templates_cluster {
  local image_dir=$1; shift
  local target_lab=$1; shift
  local target_pod=$1; shift
  local git_repo_root=$1; shift
  local extra_yaml=("$@")

  RECLASS_CLUSTER_DIR=$(cd "${git_repo_root}/mcp/reclass/classes/cluster"; pwd)
  LOCAL_PDF="${image_dir}/${target_pod}.yaml"

  for _yaml in "${extra_yaml[@]}"; do
    awk '/^---$/{f=1;next;}f' "${_yaml}" >> "${LOCAL_PDF}"
  done
  # shellcheck disable=SC2046
  j2args=$(find "${RECLASS_CLUSTER_DIR}" "$(readlink -f virsh_net)" \
           "$(readlink -f docker-compose)" $(readlink -f ./*j2) \
           -name '*.j2' -exec echo -j {} \;)
  # shellcheck disable=SC2086
  if ! python3 "${PHAROS_GEN_CFG}" -y "${LOCAL_PDF}" ${j2args} -b -v \
    -i "$(dirname "$(readlink -f "${PHAROS_IA}")")"; then
    notify_e '[ERROR] Could not convert PDF to network definitions!'
  fi
}
