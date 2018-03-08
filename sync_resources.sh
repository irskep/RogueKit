#!/bin/bash

rsync -rtvu --delete ~/_a/REXPaint/ ./Resources/xp/ || true
make csvs
