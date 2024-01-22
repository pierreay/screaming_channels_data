#!/bin/bash
./dataset.py --loglevel INFO average --nb-aes 100 $ENVRC_DATASET_PATH/240112_multi-leak-insub-1m-lna_raw $ENVRC_DATASET_PATH/240112_multi-leak-insub-1m-lna_avg train  --template -1 --plot --stop -1 --force --jobs=-1
./dataset.py --loglevel INFO average --nb-aes 300 $ENVRC_DATASET_PATH/240112_multi-leak-insub-1m-lna_raw $ENVRC_DATASET_PATH/240112_multi-leak-insub-1m-lna_avg attack --template 1 --no-plot --stop -1 --no-force --jobs=-1
