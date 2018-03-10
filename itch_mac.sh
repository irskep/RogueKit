#!/usr/bin/env bash

cd .build/Products/Debug/ && \
  zip -vr "Dr. Hallervorden.zip" "Dr. Hallervorden.app" -x "*.DS_Store" && \
  butler push "Dr. Hallervorden.zip" irskep/dr-hallervorden:mac
