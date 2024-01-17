#!/bin/bash
./dataset.py --loglevel DEBUG average --nb-aes 100 $ENVRC_DATASET_PATH/240112_multi-leak-insub-1m-lna_raw $ENVRC_DATASET_PATH/240112_multi-leak-insub-1m-lna_avg train --template -1 --plot --stop -1 --force --jobs=-1
