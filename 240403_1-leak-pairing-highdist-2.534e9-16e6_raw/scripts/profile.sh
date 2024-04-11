#!/bin/bash

DATASET=$REPO_ROOT/240403_1-leak-pairing-highdist-2.534e9-16e6_raw
SP=2000
EP=3000

function profile_comp() {
    comp=$1
    nt=$2
    pois_algo=$3
    profile=profile_${comp}_${nt}_${pois_algo}
    if [[ -d "${DATASET}/${profile}" ]]; then
        echo "[!] Profile already created: ${profile}"
        return 0
    fi
    
    plot=--no-plot
    save_images=--save-images
    $SC_SRC/attack.py ${plot} ${save_images} --norm --dataset-path ${DATASET} --num-traces ${nt} --start-point ${SP} --end-point ${EP} --comptype ${comp} profile --pois-algo ${pois_algo} --num-pois 1 --poi-spacing 2 --variable p_xor_k --align
    mv $DATASET/profile $DATASET/$profile
}

for comp in AMPLITUDE PHASE_ROT; do
    for num_traces in 5000 10000 19000 30000; do
        for pois_algo in r snr corr; do
            profile_comp $comp $num_traces $pois_algo
        done
    done
done
