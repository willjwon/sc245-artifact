#!/bin/bash
set -e

# ===================================
# Configurations
# ===================================
WORKLOAD=(
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
  3d_switch.txt
  3d_switch.txt
  3d_switch.txt
  3d_switch.txt
  3d_switch.txt
  3d_switch.txt
  3d_switch.txt
  3d_switch.txt
  3d_switch.txt
  3d_switch.txt
)
NETWORK=(
  3d_switch.json
  3d_switch.json
  3d_switch.json
  3d_switch.json
  3d_switch.json
  3d_switch.json
  3d_switch.json
  3d_switch.json
  3d_switch.json
  3d_switch.json
)
UNITS_COUNT=(
  "8 8 16"
  "8 8 16"
  "8 8 16"
  "8 8 16"
  "8 8 16"
  "8 8 16"
  "8 8 16"
  "8 8 16"
  "8 8 16"
  "8 8 16"
)
LINKS_COUNT=(
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
)
LINK_LATENCY=(
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
  "1 1 1"
)
LINK_BANDWIDTH=(
  "87.18 10.91 1.91"
  "174.36 21.82 3.82"
  "261.54 32.73 5.73"
  "348.72 43.64 7.64"
  "435.90 54.55 9.55"
  "523.08 65.46 11.46"
  "610.26 76.37 13.37"
  "697.44 87.28 15.28"
  "784.62 98.19 17.19"
  "871.80 109.10 19.10"
)
CONFIG_NAME="3d_perfcost_1t"
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