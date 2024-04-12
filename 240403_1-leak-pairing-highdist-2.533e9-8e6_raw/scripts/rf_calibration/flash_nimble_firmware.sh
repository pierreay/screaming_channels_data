#!/bin/bash

function compile_firmware() {
    cd $SC/src
    # git checkout TODO
    # PROG:
    # direnv exec . cd "$ENVRC_NIMBLE_PATH" && make all
}

# WAIT:
compile_firmware
