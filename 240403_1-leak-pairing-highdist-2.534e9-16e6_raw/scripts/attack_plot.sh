#!/bin/bash

# * About

# Perform multiple attacks and store the results in a CSV file.

# * Global configuration

# Dataset path.
DATASET=$REPO_ROOT/240403_1-leak-pairing-highdist-2.534e9-16e6_raw

# Length of the profile in samples.
PROFILE_LENGTH=1000
# Start index for attack traces.
START_POINT=2000
# Stop index for attack traces.
END_POINT=$((START_POINT + PROFILE_LENGTH))

# Path of script directory.
SCRIPT_WD="$(dirname $(realpath $0))"

# * Functions for CSV building

function iterate() {
    i_start=$1
    i_step=$2
    i_end=$(($3 - 1 ))
    # Iteration over number of traces.
    for num_traces in $(seq $i_start $i_step $i_end); do
        # Write number of traces.
        echo -n "$num_traces;" | tee -a "$OUTFILE_CSV"

        # Attack and extract:
        # 1) The key rank
        # 2) The correct number of bytes.
        # 3) The median of the PGE
        $SC_SRC/attack.py --no-log --no-plot --norm --dataset-path "$DATASET" \
                    --start-point $START_POINT --end-point $END_POINT --num-traces $num_traces --comptype $COMPTYPE attack \
                    --attack-algo pcc --profile "$PROFILE" \
                    --num-pois 1 --poi-spacing 2 --variable p_xor_k --align 2>/dev/null \
            | grep -E 'actual rounded|CORRECT|MEDIAN' \
            | cut -f 2 -d ':' \
            | tr -d ' ' \
            | tr '[\n]' '[;]' \
            | sed 's/2^//' \
            | sed 's/;$//' \
            | tee -a "$OUTFILE_CSV"

        echo "" | tee -a "$OUTFILE_CSV"
    done
}

function csv_build() {
    # Write CSV header.
    echo "trace_nb;log2(key_rank);correct_bytes;pge_median" > "$OUTFILE_CSV"
    # Get data into CSV [START STEP END].
    iterate 10 5 1000
    iterate 1000 50 10000
    iterate 10000 150 $((20000 + 1))
}

# * Script

function attack_given_profile() {
    # Configuration.
    # Profile path.
    export PROFILE=$DATASET/profile_$1_r
    # Attacked component.
    export COMPTYPE=$2

    # Generate data.
    csv_build
    # Python script name.
    pyscript=$(basename $0)
    pyscript=${pyscript/.sh/.py}
    # Plot.
    python3 "${SCRIPT_WD}/${pyscript}" $OUTFILE_CSV $OUTFILE_PDF
}

for nb_traces in 10000 19000; do
    for comp in AMPLITUDE PHASE_ROT; do
        # Output CSV file for Python.
        export OUTFILE_CSV=$DATASET/logs/attack_results_${comp}_${nb_traces}.csv
        # Output PDF file for Python.
        export OUTFILE_PDF=$DATASET/plots/attack_results_${comp}_${nb_traces}.pdf
        # Safety-guard.
        if [[ ! -f ${OUTFILE_CSV} ]]; then
            # NOTE: Add/remove "&" for parallel/serial execution.
            attack_given_profile ${comp}_${nb_traces} ${comp} &
        else
            echo "SKIP: File exists: ${OUTFILE_CSV}"
        fi
    done
done
