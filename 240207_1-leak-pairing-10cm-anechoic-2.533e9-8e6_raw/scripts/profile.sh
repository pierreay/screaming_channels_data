#!/bin/bash

dataset=$ENVRC_DATASET_PATH/230207_1-leak-pairing-10cm-anechoic-2.533e9-8e6_raw
nt=6600
sp=1000
ep=1500

function profile_comp() {
    comp=$1
    profile=profile_$comp
    ./attack.py --plot --norm --dataset-path $dataset --num-traces $nt --start-point $sp --end-point $ep --comptype $comp profile --pois-algo r --num-pois 1 --poi-spacing 2 --variable p_xor_k --align
    mv $dataset/profile $dataset/$profile
    mv ~/Figure_1.png $dataset/$profile/plot_corr.png
    mv ~/Figure_2.png $dataset/$profile/plot_poi_1.png
}

# Profile using amplitude:
profile_comp AMPLITUDE
# Profile using phase rotation:
profile_comp PHASE_ROT
