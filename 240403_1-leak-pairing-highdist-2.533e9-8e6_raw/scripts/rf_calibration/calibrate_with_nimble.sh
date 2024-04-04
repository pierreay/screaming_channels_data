#!/bin/bash

# * Variables

CONFIG_PATH="/tmp/config.toml"

CONTINUE_FLAG=1

# * Functions

function compile_firmware() {
    cd $NIMBLE
    # git checkout f879eff
    make all
}

function init_tmp_dataset() {
    (cd $SC_SRC && ./dataset.py init /tmp 8e6 --input-gen-run --input-src-pairing --nb-trace-wanted-train 10 --nb-trace-wanted-attack 5 --force)
}

function init_radio_if_needed() {
    pgrep radio
    if [[ $? == 1 ]]; then
        (cd $SC_SRC && ./radio.py --dir /tmp --loglevel DEBUG listen 128e6 2.533e9 8e6 --nf-id -1 --ff-id 0 --duration=0.5 --gain 76 &)
        sleep 3
    fi
}

function kill_radio() {
    pkill radio.py
}

function init_config() {
    rm $CONFIG_PATH
    cp $SC_SRC/config.toml $CONFIG_PATH
}

function config() {
    config_file="$1"
    param_name="$2"
    param_value="$3"
    echo "${config_file}: $param_name=$param_value" | tee -a output.log
    sed -i "s/$param_name = .*/$param_name = $param_value/g" "$config_file"
}

function instrument() {
    (cd $SC_SRC && ./radio.py --dir /tmp --config $CONFIG_PATH instrument /tmp train "C0:A5:E8:58:D2:FB" "C2:3E:54:84:5C:4C" /dev/ttyACM0 --idx 0 --config slow)
    ret=$?
    echo "INFO: ret=$ret?"
    if [[ "$ret" != 0 ]]; then
        CONTINUE_FLAG=0
    fi
}

function plot() {
    (cd $SC_SRC && ./radio.py --dir /tmp plot-file 8e6 /tmp/raw_0_0.npy --freq 2.533e9)
}

function extract() {
    (cd $SC_SRC && ./radio.py --dir /tmp extract 2.533e9 8e6 0 --plot --no-overwrite --no-exit-on-error --config 1_aes_ff_antenna_8msps)
    echo "INFO: ret=$?"
}

function capture() {
    # compile_firmware

    init_tmp_dataset

    init_radio_if_needed

    init_config
    # NOTE: Example:
    # config "$CONFIG_PATH" "trg_bp_low" "[0.5e6]"

    instrument
}

function analyze() {
    # plot
    extract
}

# * Steps

capture

if [[ $CONTINUE_FLAG == 1 ]]; then
    analyze
fi

# kill_radio
