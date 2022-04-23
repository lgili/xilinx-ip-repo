#!/bin/bash

for f in $(find . -name Makefile); do
  pushd $(dirname $f)
  make clean
  popd
done
