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
  "24.79 6.19 2.71 1.65"
  "49.57 12.39 5.42 3.30"
  "74.36 18.58 8.13 4.95"
  "99.14 24.78 10.84 6.60"
  "123.93 30.97 13.55 8.25"
  "148.71 37.17 16.26 9.90"
  "173.50 43.36 18.97 11.55"
  "198.28 49.55 21.68 13.20"
  "223.07 55.75 24.39 14.85"
  "247.85 61.94 27.10 16.50"
)
CONFIG_NAME="4d_cost_perfcost_1t"
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