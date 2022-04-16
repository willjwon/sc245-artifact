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
  2d.txt
  2d.txt
  2d.txt
  2d.txt
  2d.txt
  2d.txt
  2d.txt
  2d.txt
  2d.txt
  2d.txt
)
NETWORK=(
  2d.json
  2d.json
  2d.json
  2d.json
  2d.json
  2d.json
  2d.json
  2d.json
  2d.json
  2d.json
)
UNITS_COUNT=(
  "8 128"
  "8 128"
  "8 128"
  "8 128"
  "8 128"
  "8 128"
  "8 128"
  "8 128"
  "8 128"
  "8 128"
)
LINKS_COUNT=(
  "2 1"
  "2 1"
  "2 1"
  "2 1"
  "2 1"
  "2 1"
  "2 1"
  "2 1"
  "2 1"
  "2 1"
)
LINK_LATENCY=(
  "1 1"
  "1 1"
  "1 1"
  "1 1"
  "1 1"
  "1 1"
  "1 1"
  "1 1"
  "1 1"
  "1 1"
)
LINK_BANDWIDTH=(
  "46.11 7.78"
  "92.22 15.56"
  "138.33 23.34"
  "184.44 31.12"
  "230.55 38.90"
  "276.66 46.68"
  "322.77 54.46"
  "368.88 62.24"
  "414.99 70.02"
  "461.10 77.80"
)
CONFIG_NAME="2d_cost_perfcost_1t"
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