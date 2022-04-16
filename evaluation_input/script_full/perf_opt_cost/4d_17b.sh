#!/bin/bash
set -e

# ===================================
# Configurations
# ===================================
WORKLOAD=(
  microAllReduce.txt
)
COMM_SCALE=(
  1
)
COMPUTE_SCALE=(
  0.26
)
NUM_PASSES=1
SYSTEM=(
  4d.txt
  4d.txt
  4d.txt
  4d.txt
  4d.txt
  4d.txt
  4d.txt
  4d.txt
  4d.txt
  4d.txt
)
NETWORK=(
  4d.json
  4d.json
  4d.json
  4d.json
  4d.json
  4d.json
  4d.json
  4d.json
  4d.json
  4d.json
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
  "2 7 2 1"
  "2 7 2 1"
  "2 7 2 1"
  "2 7 2 1"
  "2 7 2 1"
  "2 7 2 1"
  "2 7 2 1"
  "2 7 2 1"
  "2 7 2 1"
  "2 7 2 1"
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
  "25.02 6.25 2.75 0.71"
  "50.03 12.51 5.49 1.42"
  "75.05 18.76 8.24 2.13"
  "100.06 25.01 10.98 2.84"
  "125.08 31.26 13.73 3.55"
  "150.09 37.52 16.47 4.26"
  "175.11 43.77 19.22 4.97"
  "200.12 50.02 21.96 5.68"
  "225.14 56.28 24.71 6.39"
  "250.15 62.53 27.45 7.10"
)
CONFIG_NAME="4d_cost_perf_17b"
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