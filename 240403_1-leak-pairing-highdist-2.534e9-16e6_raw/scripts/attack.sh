#!/bin/bash

DATASET=$REPO_ROOT/240403_1-leak-pairing-highdist-2.534e9-16e6_raw

PROFILE_LENGTH=1000
START_POINT=2000
END_POINT=$((START_POINT + PROFILE_LENGTH))
PLOT=--no-plot

function attack() {
    trace_nb=$1
    bruteforce=$2
    profile_path=$DATASET/profile_$3
    comptype=$4
    echo trace_nb=$trace_nb
    echo bruteforce=$bruteforce
    echo profile_path=$profile_path
    echo comptype=$comptype
    $SC_SRC/attack.py --log $PLOT --norm --dataset-path $DATASET --start-point $START_POINT --end-point $END_POINT --num-traces $trace_nb $bruteforce --comptype $comptype \
                      attack --attack-algo pcc --profile ${profile_path} --num-pois 1 --poi-spacing 2 --variable p_xor_k --align
}

# WAIT:
# attack 1000 --no-bruteforce AMPLITUDE_19000_r AMPLITUDE
# attack 3000 --no-bruteforce AMPLITUDE_19000_r AMPLITUDE
# attack 1000 --no-bruteforce PHASE_ROT_19000_r PHASE_ROT
# attack 3000 --no-bruteforce PHASE_ROT_19000_r PHASE_ROT
