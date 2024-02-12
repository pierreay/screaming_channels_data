#!/bin/bash

# * About

# Perform multiple attacks and store the results in a CSV file.

# * Configuration

# Dataset path.
DATASET=$REPO_ROOT/240207_1-leak-pairing-10cm-anechoic-2.533e9-8e6_raw
# Profile configuration.
PROFILE_CONFIG=AMPLITUDE_16384
# Profile path.
PROFILE=$DATASET/profile_${PROFILE_CONFIG}
# Output CSV file for Python.
OUTFILE_CSV=$DATASET/log/attack_results_${PROFILE_CONFIG}.csv
# Output PDF file for Python.
OUTFILE_PDF=$DATASET/plot/attack_results_${PROFILE_CONFIG}.pdf

# Length of the profile in samples.
PROFILE_LENGTH=500
# Start index for attack traces.
START_POINT=1000
# Stop index for attack traces.
END_POINT=$((START_POINT + PROFILE_LENGTH))

# Path of script directory.
SCRIPT_WD="$(dirname $(realpath $0))"

# * CSV building

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
                    --start-point $START_POINT --end-point $END_POINT --num-traces $num_traces attack \
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

# Progressive steps.

# 1 minutes version:
function iterate_very_short() {
    iterate 10 10 100
}

# 25 minutes version:
function iterate_short() {
    iterate 10 10 100
    iterate 100 100 1000
    iterate 1000 200 2000
    iterate 2000 500 $((15000 + 1))
}

# 1h30 version:
function iterate_long() {
    iterate 10 10 1000
    iterate 1000 100 10000
    iterate 10000 250 $((16000 + 1))
}

function csv_build() {
    # Write CSV header.
    echo "trace_nb;log2(key_rank);correct_bytes;pge_median" > "$OUTFILE_CSV"
    # Get data into CSV.
    iterate_very_short
    # iterate_short
    # iterate_long
}

# PROG:
csv_build

# * Plot data

# PROG:
$SCRIPT_WD/plot_attacks_perf.py $OUTFILE_CSV $OUTFILE_PDF
