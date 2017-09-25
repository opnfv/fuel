#!/bin/bash -ex

if [ -r "$1" ]; then
  while IFS=': ' read -r p_dest p_file; do
    if [[ "${p_dest}" =~ $2 ]]; then
      patch -fd "${p_dest}" -p1 < "/root/fuel/mcp/patches/${p_file}"
    fi
  done < "$1"
fi
