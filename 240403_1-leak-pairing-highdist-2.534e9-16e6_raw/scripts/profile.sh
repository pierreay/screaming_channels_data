#!/bin/bash

dataset=$REPO_ROOT/240403_1-leak-pairing-highdist-2.534e9-16e6_raw
sp=2000
ep=3000

function profile_comp() {
    comp=$1
    nt=$2
    profile=profile_${comp}_${nt}
    echo "[?] Save plots using 's' to Figure_1.png and Figure_2.png"
    $SC_SRC/attack.py --plot --norm --dataset-path $dataset --num-traces $nt --start-point $sp --end-point $ep --comptype $comp profile --pois-algo r --num-pois 1 --poi-spacing 2 --variable p_xor_k --align
    mv $dataset/profile $dataset/$profile
    mv ~/Figure_1.png $dataset/$profile/plot_corr.png
    mv ~/Figure_2.png $dataset/$profile/plot_poi_1.png
}

# DONE: Profile using amplitude:
profile_comp AMPLITUDE 19000
# DONE: Profile using phase rotation:
profile_comp PHASE_ROT 19000

# DONE: Profile using amplitude with more traces, while collection is still not complete, but used for the paper:
# profile_comp AMPLITUDE 27900
# DONE: Profile using phase with more traces, while collection is still not complete, but used for the paper:
# profile_comp PHASE_ROT 27900

# DONE: Profile using amplitude at 32k traces:
# profile_comp AMPLITUDE 32768
# DONE: Profile using phase at 32k traces:
# profile_comp PHASE_ROT 32768

# DONE: Profile using amplitude at 64k traces:
# profile_comp AMPLITUDE 65536
# DONE: Profile using phase at 64k traces:
# profile_comp PHASE_ROT 65536
