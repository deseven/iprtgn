#!/bin/bash

cp -r tn/iPRTGn.app $1/Contents/MacOS
cp -f Info.plist $1/Contents
#osascript -e "display notification \"$1\" with title 111"
