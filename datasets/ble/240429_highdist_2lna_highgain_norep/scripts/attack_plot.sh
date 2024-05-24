#!/bin/bash -u

# * Environment

env="$(realpath $(dirname $0))/env.sh"
echo "INFO: Source file: $env"
source "$env"

# Safety-guard.
if [[ -z $ENV_FLAG ]]; then
    echo "ERROR: Environment can't been sourced!"
    exit 1
fi

# * Variables

# ** Profile configuration

# List of parameters for the used profiles.
readonly COMP_LIST=(AMPLITUDE)
readonly NUM_TRACES_LIST=(12000 65000)
readonly POIS_ALGO_LIST=(r)
readonly POIS_NB_LIST=(1)

# Delimiters.
readonly PROFILE_LENGTH=550
readonly START_POINT=1020
readonly END_POINT=$((START_POINT + PROFILE_LENGTH))

# ** Attack configuration

# Paths.
readonly METASET_LIST=(raw) # raw avg ext

# ** Internals

# Paths.
readonly PROFILE_PATH_BASE="${DATASET_PATH}/raw/profiles"
readonly CSV_PATH_BASE="${DATASET_PATH}/csv"
readonly PLOT_PATH_BASE="${DATASET_PATH}/plots"

# Path of script directory.
SCRIPT_WD="$(dirname $(realpath $0))"

# * Functions for CSV building

function attack() {
    # Get parameters.
    local metaset="${1}"
    local comp="${2}"
    local num_traces="${3}"
    local pois_algo="${4}"
    local pois_nb="${5}"
    local i_start="${6}"
    local i_step="${7}"
    local i_end=$(( $8 - 1 ))
    local mode="${9}" # [1 = Initialize CSV ; 0 = Append to CSV ; 2 = Finalize CSV]
    # Set parameters.
    local metaset_path="${DATASET_PATH}/${metaset}"
    local profile_path="${PROFILE_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}"
    local csv_path="${CSV_PATH_BASE}/attack_${metaset}_${comp}_${num_traces}_${pois_algo}_${pois_nb}.csv"
    local sentinel_path="${CSV_PATH_BASE}/.attack_${metaset}_${comp}_${num_traces}_${pois_algo}_${pois_nb}.done"
    local custom_dtype="--no-custom-dtype"
    if [[ "${metaset}" == "raw" ]]; then
        custom_dtype="--custom-dtype"
    fi
    local align_attack="--align-attack"
    local align_profile="--align-profile"
    local align_profile_avg="--no-align-profile-avg"

    if [[ "${mode}" == 1 ]]; then
        # Safety-guard for initialization.
        if [[ -f "${csv_path}" ]]; then
            echo "[!] SKIP: Attack: File exists: ${csv_path}"
            return 0
        fi

        # Initialize directories.
        mkdir -p "${CSV_PATH_BASE}"
        # Write CSV header.
        echo "trace_nb;log2(key_rank);correct_bytes" | tee "${csv_path}"
    fi

    # Safety-guard for continuation.
    if [[ -f "${sentinel_path}" ]]; then
        echo "[!] SKIP: Attack: File exists: ${sentinel_path}"
        return 0
    fi    

    echo "INFO: Process: ${csv_path}"
    
    # Iteration over number of traces.
    for num_traces_attack in $(seq $i_start $i_step $i_end); do
        # Write number of traces.
        echo -n "${num_traces_attack};" | tee -a "$csv_path"

        # Attack and extract:
        # 1) The key rank
        # 2) The correct number of bytes.
        "${SC_SRC}"/attack.py "${custom_dtype}" --no-log --no-plot --norm --dataset-path "${metaset_path}" --start-point "${START_POINT}" --end-point "${END_POINT}" --num-traces "${num_traces_attack}" --no-bruteforce \
                   attack-recombined --comptype "${comp}" --attack-algo pcc --profile "${profile_path}" --num-pois "${pois_nb}" --poi-spacing 1 --variable p_xor_k "${align_attack}" "${align_profile}" "${align_profile_avg}" \
                   2>/dev/null \
            | grep -E 'actual rounded|CORRECT' \
            | cut -f 2 -d ':' \
            | tr -d ' ' \
            | tr '[\n]' '[;]' \
            | sed 's/2^//' \
            | sed 's/;$//' \
            | tee -a "$csv_path"

        echo "" | tee -a "$csv_path"
    done

    if [[ "${mode}" == 2 ]]; then
        # Create sentinel.
        touch "${sentinel_path}"
    fi
}

# * Script

# ** CSV

for metaset in "${METASET_LIST[@]}"; do
    for comp in "${COMP_LIST[@]}"; do
        for num_traces in "${NUM_TRACES_LIST[@]}"; do
            for pois_algo in "${POIS_ALGO_LIST[@]}"; do
                for pois_nb in "${POIS_NB_LIST[@]}"; do
                    # [START ; STEP ; END ; MODE]
                    # NOTE: 1h40 long.
                    attack "${metaset}" "${comp}" "${num_traces}" "${pois_algo}" "${pois_nb}" 10 5 500 1
                    attack "${metaset}" "${comp}" "${num_traces}" "${pois_algo}" "${pois_nb}" 500 50 1000 0
                    attack "${metaset}" "${comp}" "${num_traces}" "${pois_algo}" "${pois_nb}" 1000 500 10000 0
                    attack "${metaset}" "${comp}" "${num_traces}" "${pois_algo}" "${pois_nb}" 10000 2500 40000 2
                done
            done
        done
    done
done

# ** PDF

pdf_path="${PLOT_PATH_BASE}/attack_all.pdf"

# Safety-guard.
if [[ -f "${pdf_path}" ]]; then
    echo "[!] SKIP: Plot: File exists: ${pdf_path}"
    exit 0
fi
echo "INFO: Process: ${pdf_path}"

mkdir -p "${PLOT_PATH_BASE}"
"$(realpath ${0/.sh/.py})" "${CSV_PATH_BASE}" "${pdf_path}"
