#!/bin/bash

cp -r tn/iPRTGn.app $1/Contents/MacOS
cp -f res/Info.plist $1/Contents
#osascript -e "display notification \"cp -f Info.plist $1/Contents\" with title 111"
