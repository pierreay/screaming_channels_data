#!/bin/bash

dataset=$REPO_ROOT/240207_1-leak-pairing-10cm-anechoic-2.533e9-8e6_raw
profile=$REPO_ROOT/240207_1-leak-pairing-10cm-anechoic-2.533e9-8e6_raw/profile_AMPLITUDE
profile_length=500
start_point=1000
end_point=$((start_point + profile_length))
plot=--no-plot

function attack() {
    trace_nb=$1
    echo "Using $trace_nb traces with 1 POI:"
    $SC_SRC/attack.py --log $plot --norm --dataset-path $dataset --start-point $start_point --end-point $end_point --num-traces $trace_nb $2 attack --attack-algo pcc --profile ${profile} --num-pois 1 --poi-spacing 2 --variable p_xor_k --align
}

#attack 500
#attack 1000
#attack 2000
#attack 3000
#attack 4000
attack 14900 --bruteforce
