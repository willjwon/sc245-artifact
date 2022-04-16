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
  3d.txt
  3d.txt
  3d.txt
  3d.txt
  3d.txt
  3d.txt
  3d.txt
  3d.txt
  3d.txt
  3d.txt
)
NETWORK=(
  3d.json
  3d.json
  3d.json
  3d.json
  3d.json
  3d.json
  3d.json
  3d.json
  3d.json
  3d.json
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
  "2 7 1"
  "2 7 1"
  "2 7 1"
  "2 7 1"
  "2 7 1"
  "2 7 1"
  "2 7 1"
  "2 7 1"
  "2 7 1"
  "2 7 1"
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
  "43.78 1.57 1.49"
  "87.55 3.13 2.98"
  "131.33 4.70 4.47"
  "175.10 6.26 5.96"
  "218.88 7.83 7.45"
  "262.65 9.39 8.94"
  "306.43 10.96 10.43"
  "350.20 12.53 11.92"
  "393.98 14.09 13.41"
  "437.75 15.66 14.90"
)
CONFIG_NAME="3d_cost_perf_17b"
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