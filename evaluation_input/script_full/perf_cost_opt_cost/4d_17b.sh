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
  "43.72 1.57 0.70 0.16"
  "87.44 3.15 1.39 0.32"
  "131.16 4.72 2.09 0.48"
  "174.88 6.30 2.78 0.64"
  "218.60 7.87 3.48 0.80"
  "262.32 9.45 4.17 0.96"
  "306.04 11.02 4.87 1.12"
  "349.76 12.59 5.56 1.28"
  "393.48 14.17 6.26 1.44"
  "437.20 15.74 6.95 1.60"
)
CONFIG_NAME="4d_cost_perfcost_17b"
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