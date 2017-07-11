#!/bin/sh

if [ -r "$1" ]; then
  while IFS=': ' read -r p_dest p_file; do
    patch -d $p_dest -p1 < /root/fuel/mcp/patches/$p_file
  done < $1
fi

