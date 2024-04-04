#!/bin/bash

# * Global variables

# ** Script configuration

# *** Paths

# Path of current dataset.
DATASET_PATH="$REPO_ROOT/240403_1-leak-pairing-highdist-2.533e9-8e6_raw"

# *** Parameters

# Center frequency.
FC=2.533e9
# Sampling rate.
FS=8e6
# Bandpass filter for trigger signal. NOTE: Depends on sampling rate.
# TRG_BP_LOW="[1.0e6]"
# TRG_BP_HIGH="[1.9e6]"
# Minimum accepted SNR.
ACCEPT_SNR_MIN=4.9

# *** Actions

REFLASH=1
EXTRACT=1
KILL_RADIO=1

# ** Internals

CONTINUE_FLAG=1

CONFIG_PATH="/tmp/config.toml"

# * Functions

function compile_firmware() {
    cd $NIMBLE
    git checkout f879eff
    make all
}

function init_git() {
    (cd $SC_SRC && git checkout afc99e7)
}

function init_tmp_dataset() {
    (cd $SC_SRC && ./dataset.py init /tmp ${FS} --input-gen-run --input-src-pairing --nb-trace-wanted-train 10 --nb-trace-wanted-attack 5 --force)
}

function init_radio_if_needed() {
    pgrep radio
    if [[ $? == 1 ]]; then
        (cd $SC_SRC && ./radio.py --dir /tmp --loglevel DEBUG listen 128e6 ${FC} ${FS} --nf-id -1 --ff-id 0 --duration=0.5 --gain 76 &)
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

# Example:
# config "$CONFIG_PATH" "trg_bp_low" "[0.5e6]"
function config() {
    config_file="$1"
    param_name="$2"
    param_value="$3"
    echo "${config_file}: ${param_name}=${param_value}"
    sed -i "s/${param_name} = .*/${param_name} = ${param_value}/g" "${config_file}"
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
    (cd $SC_SRC && ./radio.py --dir /tmp plot-file ${FS} /tmp/raw_0_0.npy --freq ${FC})
}

function extract() {
    (cd $SC_SRC && ./radio.py --dir /tmp --config $CONFIG_PATH extract ${FC} ${FS} 0 --plot --no-overwrite --no-exit-on-error --config 1_aes_ff_antenna_8msps --save-plot="$DATASET_PATH/plots/calibrate_nimble" )
    echo "INFO: ret=$?"
}

function capture() {
    if [[ $REFLASH == 1 ]]; then
        compile_firmware
    fi

    init_tmp_dataset

    init_radio_if_needed

    init_config
    config "$CONFIG_PATH" "accept_snr_min" "${ACCEPT_SNR_MIN}"
    # config "$CONFIG_PATH" "trg_bp_low" "${TRG_BP_LOW}"
    # config "$CONFIG_PATH" "trg_bp_high" "${TRG_BP_HIGH}"

    instrument
}

function analyze() {
    if [[ $EXTRACT == 1 ]]; then
        extract
    else
        plot
    fi
}

function init_log() {
    clear
}

function save_log() {
    tmux capture-pane -pS - >> "$DATASET_PATH/logs/calibrate_nimble.log"
}

# * Steps

init_log

init_git

capture

if [[ $CONTINUE_FLAG == 1 ]]; then
    analyze
fi

if [[ $KILL_RADIO == 1 ]]; then
    kill_radio
fi

save_log
