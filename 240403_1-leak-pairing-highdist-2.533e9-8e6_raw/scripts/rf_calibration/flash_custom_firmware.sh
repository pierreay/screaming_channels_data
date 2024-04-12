#!/bin/bash

function compile_firmware() {
    cd $SC_POC/firmware
    # git checkout 276e0c4
    direnv exec . make -C pca10040/blank/armgcc flash
}

# DONE:
# compile_firmware

# NOTE: Then, use minicom, press "a" "02" "ENTER" then alternate "o" and "c"
# with GQRX opened to find setup increasing SNR at maximum.
