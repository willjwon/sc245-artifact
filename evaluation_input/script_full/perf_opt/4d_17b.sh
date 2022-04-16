#!/bin/bash
set -e

# ===================================
# Configurations
# ===================================
WORKLOAD=(
  transformer_17B.txt
  transformer_175B.txt
  transformer_1T.txt
)
COMM_SCALE=(
  1
)
COMPUTE_SCALE=(
  0.26
)
NUM_PASSES=1
SYSTEM=(
  4d_switch.txt
  4d_switch.txt
  4d_switch.txt
  4d_switch.txt
  4d_switch.txt
  4d_switch.txt
  4d_switch.txt
  4d_switch.txt
  4d_switch.txt
  4d_switch.txt
)
NETWORK=(
  4d_switch.json
  4d_switch.json
  4d_switch.json
  4d_switch.json
  4d_switch.json
  4d_switch.json
  4d_switch.json
  4d_switch.json
  4d_switch.json
  4d_switch.json
)
UNITS_COUNT=(
  "2 8 8 8"
  "2 8 8 8"
  "2 8 8 8"
  "2 8 8 8"
  "2 8 8 8"
  "2 8 8 8"
  "2 8 8 8"
  "2 8 8 8"
  "2 8 8 8"
  "2 8 8 8"
)
LINKS_COUNT=(
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
)
LINK_LATENCY=(
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
  "1 1 1 1"
)
LINK_BANDWIDTH=(
  "50.03 43.77 5.49 0.71"
  "100.06 87.54 10.98 1.42"
  "150.09 131.31 16.47 2.13"
  "200.12 175.08 21.96 2.84"
  "250.15 218.85 27.45 3.55"
  "300.18 262.62 32.94 4.26"
  "350.21 306.39 38.43 4.97"
  "400.24 350.16 43.92 5.68"
  "450.27 393.93 49.41 6.39"
  "500.30 437.70 54.90 7.10"
)
CONFIG_NAME="4d_perf_17b"
# ===================================
# ===================================

# Absolute paths to useful directories
INPUT_DIR="/app/evaluation_input"
BINARY="/app/astra-sim/build/astra_analytical/build/AnalyticalAstra/bin/AnalyticalAstra"
STATS="/output/full/${CONFIG_NAME}"
mkdir -p ${STATS}


# run test
current_row=-1
tot_stat_row=$((${#WORKLOAD[@]} * ${#SYSTEM[@]} * ${#COMM_SCALE[@]}))

for workload in "${WORKLOAD[@]}"; do
  for comm_scale in "${COMM_SCALE[@]}"; do
    for comp_scale in "${COMPUTE_SCALE[@]}"; do
      for i in "${!SYSTEM[@]}"; do
        current_row=$(($current_row + 1))
        filename="${CONFIG_NAME}-${workload}-${NETWORK[${i}]}-${SYSTEM[${i}]}-${comm_scale}-${comp_scale}-${UNITS_COUNT[${i}]}-${LINKS_COUNT[${i}]}-${LINK_BANDWIDTH[${i}]}-${NUM_PASSES}"

        echo "[SCRIPT] Initiate ${filename}"

        "${BINARY}" \
          --network-configuration="${INPUT_DIR}/network/${NETWORK[${i}]}" \
          --system-configuration="${INPUT_DIR}/system/${SYSTEM[${i}]}" \
          --workload-configuration="${INPUT_DIR}/workload/${workload}" \
          --path="${STATS}/" \
          --units-count ${UNITS_COUNT[${i}]} \
          --links-count ${LINKS_COUNT[${i}]} \
          --link-bandwidth ${LINK_BANDWIDTH[${i}]} \
          --link-latency ${LINK_LATENCY[${i}]} \
          --num-passes ${NUM_PASSES} \
          --num-queues-per-dim 1 \
          --comm-scale ${comm_scale} \
          --compute-scale ${comp_scale} \
          --injection-scale 1 \
          --rendezvous-protocol false \
          --total-stat-rows "${tot_stat_row}" \
          --stat-row "${current_row}" \
          --run-name "${filename}" >> "${STATS}"/"${filename}".txt &
      done
    done
  done
done