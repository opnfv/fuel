#!/bin/bash

MISSING_FILES="keyboard.js keysymdef.js keysym.js"
NOVNC_SOURCE="http://raw.githubusercontent.com/kanaka/noVNC/v0.5.1/include"

for file in $MISSING_FILES
do
  wget -P package/usr/share/novnc/include/ "$NOVNC_SOURCE/$file"
done
