#!/bin/bash

DATASET=$REPO_ROOT/240403_1-leak-pairing-highdist-2.534e9-16e6_raw
LOGFILE_PATH=${DATASET}/logs/attack.log

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
    if [[ "$comptype" == "RECOMBIN" ]]; then
        $SC_SRC/attack.py --log $PLOT --norm --dataset-path $DATASET --start-point $START_POINT --end-point $END_POINT --num-traces $trace_nb $bruteforce \
                          attack-recombined --attack-algo pcc --profile ${profile_path} --num-pois 1 --poi-spacing 2 --variable p_xor_k --align
    else
        $SC_SRC/attack.py --log $PLOT --norm --dataset-path $DATASET --start-point $START_POINT --end-point $END_POINT --num-traces $trace_nb $bruteforce --comptype $comptype \
                          attack --attack-algo pcc --profile ${profile_path} --num-pois 1 --poi-spacing 2 --variable p_xor_k --align
    fi
}

if [[ -f ${LOGFILE_PATH} ]]; then
    echo "[!] Attack had already be executed: ${LOGFILE_PATH}"
    exit 0
fi

clear
mkdir -p "${DATASET}/logs"

(cd $SC && git checkout feat-recombination)

# Compare components results (including recombination):
for comp in AMPLITUDE PHASE_ROT RECOMBIN; do
    if [[ "$comp" != "RECOMBIN" ]]; then
        attack 7000 --no-bruteforce ${comp}_19000_r ${comp}
    else
        attack 7000 --no-bruteforce '{}_19000_r' ${comp}
    fi
done

# Compare number of traces results:
for num_traces in 1000 3000 7000; do
    attack ${num_traces} --no-bruteforce AMPLITUDE_19000_r AMPLITUDE
done

# Compare POIS algorithm results:
for pois_algo in r snr corr; do
    attack 7000 --no-bruteforce AMPLITUDE_19000_${pois_algo} AMPLITUDE
done

tmux capture-pane -pS - > ${LOGFILE_PATH}

grep -E "=|actual.rounded" "${LOGFILE_PATH}" > ${LOGFILE_PATH/.log/_summary.log}
