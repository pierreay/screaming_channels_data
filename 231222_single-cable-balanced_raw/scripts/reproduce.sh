# Profile:
./attack.py --plot --norm --dataset-path ~/storage/dataset/231222_single-cable-balanced_raw --num-traces 65536 --start-point 73950 --end-point 74350 profile --pois-algo r --num-pois 2 --poi-spacing 1 --variable p_xor_k --align
# Attack:
./attack.py --plot --norm --dataset-path ~/storage/dataset/231222_single-cable-balanced_raw --num-traces 4000 --start-point 73950 --end-point 74350 attack --attack-algo pcc --num-pois 2 --poi-spacing 1 --variable p_xor_k --align
