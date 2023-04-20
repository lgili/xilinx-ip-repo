#!/bin/bash

PATH_LUGMIARM=$(realpath $(dirname $0))
declare -a StringArray=("/axi_clock" "/axi_dma" "/")


for val in $(ls -d */); do
  cd $PATH_LUGMIARM/${val} 
  make clean
done
