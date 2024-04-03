#!/bin/bash

cd $SC_POC/firmware
# git checkout 276e0c4
direnv exec . make -C pca10040/blank/armgcc flash
