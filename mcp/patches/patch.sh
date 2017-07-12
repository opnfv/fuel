#!/bin/bash

if [ -r "$1" ]; then
  while IFS=': ' read -r p_dest p_file; do
    [[ "${p_dest}" =~ $2 ]] && patch -fd "${p_dest}" -p1 < "/root/fuel/mcp/patches/${p_file}"
  done < $1
fi
