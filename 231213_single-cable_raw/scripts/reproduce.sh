cd ~/git/screaming_channels_ble/src
./attack.py --plot --norm --dataset-path ~/storage/dataset/single_cable_raw --num-traces 44700 --start-point 73600 --end-point 74000 profile --pois-algo r --num-pois 2 --poi-spacing 2 --variable p_xor_k --align
./attack.py --plot --norm --dataset-path ~/storage/dataset/single_cable_raw --num-traces 2500 --start-point 73600 --end-point 74000 --bruteforce attack --attack-algo pcc --num-pois 2 --poi-spacing 2 --variable p_xor_k --align
