#!/bin/bash

# * Variables

# Paths.
DATASET=$REPO_ROOT/240403_1-leak-pairing-highdist-2.534e9-16e6_raw
LOGFILE_PATH=${DATASET}/logs/attack.log

# Parameters.
PROFILE_LENGTH=1000
START_POINT=2000
END_POINT=$((START_POINT + PROFILE_LENGTH))
PLOT=--no-plot

# Actions.
COMPARE_PNB=1
COMPARE_ANB=1
COMPARE_ALGO=1
COMPARE_COMP=1

# * Functions

function attack() {
    trace_nb=$1
    bruteforce=$2
    profile_path=$DATASET/profile_$3
    comptype=$4
    echo trace_nb=$trace_nb
    echo bruteforce=$bruteforce
    echo profile_path=$profile_path
    echo comptype=$comptype
    $SC_SRC/attack.py --log $PLOT --norm --dataset-path $DATASET --start-point $START_POINT --end-point $END_POINT --num-traces $trace_nb $bruteforce \
                      attack-recombined --comptype $comptype --attack-algo pcc --profile ${profile_path} --num-pois 1 --poi-spacing 1 --variable p_xor_k --align
}

# * Script

if [[ -f ${LOGFILE_PATH} ]]; then
    echo "[!] Attack had already be executed: ${LOGFILE_PATH}"
    exit 0
fi

clear
mkdir -p "${DATASET}/logs"

(cd $SC && git checkout feat-recombination)

# Compare number of traces for profile:
if [[ $COMPARE_PNB == 1 ]]; then
    for num_traces in 5000 10000 19000 30000; do
        attack 3000 --no-bruteforce AMPLITUDE_${num_traces}_corr AMPLITUDE
    done
fi

# Compare number of traces for attacks:
if [[ $COMPARE_ANB == 1 ]]; then
    for num_traces in 1000 3000 7000 20000; do
        attack ${num_traces} --no-bruteforce AMPLITUDE_10000_corr AMPLITUDE
    done
fi

# Compare POIS algorithm:
if [[ $COMPARE_ALGO == 1 ]]; then
    for pois_algo in r snr corr; do
        attack 3000 --no-bruteforce AMPLITUDE_10000_${pois_algo} AMPLITUDE
    done
fi

# Compare components results (including recombination):
if [[ $COMPARE_COMP == 1 ]]; then
    for comp in AMPLITUDE PHASE_ROT RECOMBIN; do
        attack 3000 --no-bruteforce '{}_10000_corr' ${comp}
    done
fi

tmux capture-pane -pS - > ${LOGFILE_PATH}

grep -E "=|actual.rounded" "${LOGFILE_PATH}" > ${LOGFILE_PATH/.log/_summary.log}
