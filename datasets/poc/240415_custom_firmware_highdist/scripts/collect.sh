#!/bin/bash

# * Variables

# ** Configuration

# Logging level for Python.
LOG_LEVEL=INFO

# Number of traces.
NUM_TRACES=16000

# If we are collecting a train set or an attack set.
MODE="train"
# MODE="attack"

# Dataset path.
DATASET_PATH="${REPO_DATASET_PATH}/poc/240415_custom_firmware_highdist"

# Temporary collection path.
TARGET_PATH="${DATASET_PATH}/${MODE}"

# ** Actions

# Reflash the custom firmware.
REFLASH_FIRMWARE=1

# ** Internals

CALIBRATION_FLAG_PATH="${TARGET_PATH}/.calibration_done"
COLLECTION_FLAG_PATH="${TARGET_PATH}/.collection_started"

TMP_TRACE_PATH=$HOME/storage/tmp/raw_0_0.npy

# * Functions

# ** Firmware

function flash_firmware_once() {
    firmware_src="${SC_POC}/firmware/pca10040/blank/armgcc/_build/nrf52832_xxaa.hex"
    firmware_dst="${DATASET_PATH}/bin/nrf52832_xxaa.hex"
    if [[ -f "${firmware_dst}" ]]; then
        echo "SKIP: Flash firmware: File exists: ${firmware_dst}"
    fi
    
    echo "INFO: Checkout feat-recombination-corr -> $SC_POC"
    cd $SC_POC/firmware

    echo "INFO: Flash custom firmware..."
    git checkout feat-recombination-corr
    make -C pca10040/blank/armgcc flash
    echo "INFO: Save firmware: ${firmware_src} -> ${firmware_dst}"
    mkdir -p "$(dirname "$firmware_dst")" && cp "${firmware_src}" "${firmware_dst}"
    echo "DONE!"
}

# ** Configuration

function configure_param_json_escape_path() {
    # 1. Substitute "/" to "\/".
    # 2. Add '"' around string.
    echo \"${1//\//\\/}\"
}

function configure_param_json() {
    config_file="$1"
    param_name="$2"
    param_value="$3"
    echo "$config_file: $param_name=$param_value"
    # NOTE: Handle special-case where there is no "," at the end.
    candid=$(cat "$config_file" | grep "$param_name")
    if [[ ${candid:$((${#candid} - 1)):1} == "," ]]; then
        sed -i "s/\"${param_name}\": .*,/\"${param_name}\": ${param_value},/g" "$config_file"
    else
        sed -i "s/\"${param_name}\": .*/\"${param_name}\": ${param_value}/g" "$config_file"
    fi
}

function configure_json_common() {
    export CONFIG_JSON_PATH_SRC=$SC_POC/experiments/config/example_collection_collect_plot.json
    cp $CONFIG_JSON_PATH_SRC $CONFIG_JSON_PATH_DST
    configure_param_json $CONFIG_JSON_PATH_DST "channel" "20"
    configure_param_json $CONFIG_JSON_PATH_DST "bandpass_lower" "2.10e6"
    configure_param_json $CONFIG_JSON_PATH_DST "bandpass_upper" "2.30e6"
    configure_param_json $CONFIG_JSON_PATH_DST "drop_start" "2e-1"
    configure_param_json $CONFIG_JSON_PATH_DST "trigger_threshold" "190e3"
    # Shift right -> increase offset / Shift left -> decrease offset.
    configure_param_json $CONFIG_JSON_PATH_DST "trigger_offset" "0e-6"
    configure_param_json $CONFIG_JSON_PATH_DST "trigger_rising" "true"
    configure_param_json $CONFIG_JSON_PATH_DST "signal_length" "200e-6"
    configure_param_json $CONFIG_JSON_PATH_DST "num_traces_per_point" 300
    configure_param_json $CONFIG_JSON_PATH_DST "num_traces_per_point_keep" 1
    configure_param_json $CONFIG_JSON_PATH_DST "modulate" "true"
    configure_param_json $CONFIG_JSON_PATH_DST "min_correlation" "1.4e20"
}

function configure_json_plot() {
    export CONFIG_JSON_PATH_DST=$TARGET_PATH/example_collection_collect_plot.json
    configure_json_common
    configure_param_json $CONFIG_JSON_PATH_DST "num_points" 1
}

function configure_json_collect() {
    export CONFIG_JSON_PATH_DST=$TARGET_PATH/example_collection_collect.json
    configure_json_common
    configure_param_json $CONFIG_JSON_PATH_DST "num_points" "$NUM_TRACES"
    configure_param_json $CONFIG_JSON_PATH_DST "template_name" "$(configure_param_json_escape_path $TARGET_PATH/template.npy)"
    if [[ $MODE == "train" ]]; then
        configure_param_json $CONFIG_JSON_PATH_DST "fixed_key" "false"
    elif [[ $MODE == "attack" ]]; then
        configure_param_json $CONFIG_JSON_PATH_DST "fixed_key" "true"
    fi
}

# ** Instrumentation

function record() {
    # Get args.
    plot=$1
    saveplot=$2
    
    # Kill previously started radio server.
    pkill radio.py

    sudo ykushcmd -d a # power off all ykush device
    sleep 2
    sudo ykushcmd -u a # power on all ykush device
    sleep 4

    # Start SDR server.
    # NOTE: Make sure the JSON config file is configured accordingly to the SDR server here.
    $SC_SRC/radio.py --config $SC_SRC/config.toml --dir $HOME/storage/tmp --loglevel $LOG_LEVEL listen 128e6 2.533e9 8e6 --nf-id -1 --ff-id 0 --duration=0.3 --gain 76 &
    sleep 10

    # Start collection and plot result.
    sc-experiment --loglevel=$LOG_LEVEL --radio=USRP --device=$(nrfjprog --com | cut - -d " " -f 5) -o $TMP_TRACE_PATH collect $CONFIG_JSON_PATH_DST $TARGET_PATH $plot $saveplot --average-out=$TARGET_PATH/template.npy
}

function analyze_only() {
    sc-experiment --loglevel=$LOG_LEVEL --radio=USRP --device=$(nrfjprog --com | cut - -d " " -f 5) -o $TMP_TRACE_PATH extract $CONFIG_JSON_PATH_DST $TARGET_PATH --plot --average-out=$TARGET_PATH/template.npy
}

# * Script

# Ensure collection directory is created.
mkdir -p $TARGET_PATH

# ** Step 1: Calibrate and generate a template

# If calibration has not been done.
if [[ ! -f "$CALIBRATION_FLAG_PATH" ]]; then
    # Flash custom firmware.
    flash_firmware_once

    # Set the JSON configuration file for one recording analysis.
    configure_json_plot

    # Record a new trace if not already done.
    if [[ ! -f "${TMP_TRACE_PATH}" ]]; then
        record --plot --saveplot
    # Analyze only.
    else
        echo "SKIP: New recording: File exists: ${TMP_TRACE_PATH}"
        analyze_only
    fi

    read -p "Press [ENTER] to confirm calibration, otherwise press [CTRL-C]..."
    touch $CALIBRATION_FLAG_PATH
else
    echo "SKIP: Calibration: File exists: $CALIBRATION_FLAG_PATH"
fi

# ** Step 2: Collect

if [[ ! -f $TARGET_PATH/template.npy ]]; then
    echo "Template has not been created! (no file at $TARGET_PATH/template.npy)"
    exit 1
fi

# If collection has not been started.
if [[ ! -f "$COLLECTION_FLAG_PATH" ]]; then
    touch $COLLECTION_FLAG_PATH
    configure_json_collect
    record --no-plot --no-saveplot
else
    echo "SKIP: Collection: File exists: $COLLECTION_FLAG_PATH"
fi
