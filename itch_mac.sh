#!/usr/bin/env bash

rm -rf "Dr. Hallervorden"
mkdir -p "Dr. Hallervorden"
cp Game_Readme.txt "Dr. Hallervorden/Cheats, spoilers, and strategy.txt"
cp -r ".build/Products/Debug/Dr. Hallervorden.app" "Dr. Hallervorden/"
zip -vr "Dr. Hallervorden.zip" "Dr. Hallervorden" -x "*.DS_Store"
#butler push "Dr. Hallervorden.zip" irskep/dr-hallervorden:mac
