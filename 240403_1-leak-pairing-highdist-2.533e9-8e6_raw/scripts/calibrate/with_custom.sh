#!/bin/bash

# * Functions

function compile_flash_firmware() {
    cd $SC_POC/firmware
    git checkout 276e0c4
    direnv exec . make -C pca10040/blank/armgcc flash
}

function start_tx() {
    script=/tmp/script.minicom
    cat << EOF > $script
send a
send 02
send o
! killall -9 minicom
EOF
    minicom -D /dev/ttyACM0 -S $script >/dev/null 2>/dev/null &
    
}

function stop_tx() {
    script=/tmp/script.minicom
    cat << EOF > $script
send e
! killall -9 minicom
EOF
    minicom -D /dev/ttyACM0 -S $script >/dev/null 2>/dev/null &
}

# * Steps

compile_flash_firmware

start_tx

echo "INFO: Tune to 2.402 GHz and observe modulated carrier"
gqrx

stop_tx
