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
  "21.98 5.50 7.81 1.95"
  "43.96 10.99 15.62 3.90"
  "65.94 16.49 23.43 5.85"
  "87.92 21.98 31.24 7.80"
  "109.90 27.48 39.05 9.75"
  "131.88 32.97 46.86 11.70"
  "153.86 38.47 54.67 13.65"
  "175.84 43.97 62.48 15.60"
  "197.82 49.46 70.29 17.55"
  "219.80 54.96 78.10 19.50"
)
CONFIG_NAME="4d_cost_perf_175b"
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