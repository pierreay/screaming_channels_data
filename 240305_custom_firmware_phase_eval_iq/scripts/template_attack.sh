#!/bin/bash

# * Parameters

# Path of dataset used to create the profile.
TRAIN_SET=$REPO_ROOT/240305_custom_firmware_phase_eval_iq/train
# Base path used to store the created profile.
PROFILE_PATH_BASE=$TRAIN_SET/../profile
# Path of dataset used to perform the attack.
ATTACK_SET=$REPO_ROOT/240305_custom_firmware_phase_eval_iq/attack

# Number of traces to use for profile creation.
NUM_TRACES_PROFILE=10900
# Number of traces to use for attack.
NUM_TRACES_ATTACK=15000
# Delimiters.
START_POINT=0
END_POINT=0

# * Functions

function profile_comp() {
    # Get parameters.
    comp=$1
    # Set global parameters.
    export PROFILE_PATH=${PROFILE_PATH_BASE}_${comp}_${NUM_TRACES_PROFILE}
    # Initialize directories.
    mkdir -p $PROFILE_PATH

    # Create the profile.
    profile

    # Check result.
    if [[ ! -f $PROFILE_PATH/PROFILE_MEAN_TRACE.npy ]]; then
        echo "Profile has not been created! (no file at $PROFILE_PATH/*.npy)"
        exit 1
    fi
}

function profile() {
    echo "Press 's' to save figs to ~/Figure_1.png and ~/Figure_2.png"
    sc-attack --plot --norm --data-path $TRAIN_SET --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_PROFILE --comp $comp profile $PROFILE_PATH --pois-algo r --num-pois 1 --poi-spacing 2 --variable p_xor_k
    mv ~/Figure_1.png $PROFILE_PATH/plot_mean_trace.png
    mv ~/Figure_2.png $PROFILE_PATH/plot_poi_1.png
}

function attack_comp() {
    # Get parameters.
    comp=$1
    # Set global parameters.
    export PROFILE_PATH=${PROFILE_PATH_BASE}_${comp}_${NUM_TRACES_PROFILE}
    # Perform the attack.
    attack
}

function attack() {
    # NOTE: Sampling rate is hardcoded in collect_*.sh scripts.
    fs=8e6
    # bruteforce="--bruteforce"
    sc-attack --plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_ATTACK $bruteforce --comp $comp \
              attack $PROFILE_PATH --attack-algo pcc --variable p_xor_k --align --fs $fs
}

# * Script

# ** Profiles

# WAIT: Profile the amplitude:
# profile_comp amp

# WAIT: Profile the phase rotation:
# profile_comp phr

# WAIT: Profile the I component:
# profile_comp i

# WAIT: Profile the Q component:
# profile_comp q

# WAIT: Profile the I augmented component:
# profile_comp i_augmented

# WAIT: Profile the Q augmented component:
# profile_comp q_augmented

# ** Attacks

# Attack using previously created templates.

# WAIT:
# attack_comp amp
# WAIT:
# attack_comp phr
# WAIT:
# attack_comp i
# WAIT:
# attack_comp q
# WAIT:
# attack_comp i_augmented
# WAIT:
# attack_comp q_augmented
