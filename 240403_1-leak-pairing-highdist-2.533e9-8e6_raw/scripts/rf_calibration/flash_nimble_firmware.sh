#!/bin/bash

# * Functions

function compile_firmware() {
    cd $NIMBLE
    # git checkout f879eff
    make all
}

# * Steps

# DONE:
# compile_firmware
