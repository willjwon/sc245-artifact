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
  2d_switch.txt
  2d_switch.txt
  2d_switch.txt
  2d_switch.txt
  2d_switch.txt
  2d_switch.txt
  2d_switch.txt
  2d_switch.txt
  2d_switch.txt
  2d_switch.txt
)
NETWORK=(
  2d_switch.json
  2d_switch.json
  2d_switch.json
  2d_switch.json
  2d_switch.json
  2d_switch.json
  2d_switch.json
  2d_switch.json
  2d_switch.json
  2d_switch.json
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
  "92.22 7.78"
  "184.44 15.56"
  "276.66 23.34"
  "368.88 31.12"
  "461.10 38.90"
  "553.32 46.68"
  "645.54 54.46"
  "737.76 62.24"
  "829.98 70.02"
  "922.20 77.80"
)
CONFIG_NAME="2d_perfcost_1t"
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