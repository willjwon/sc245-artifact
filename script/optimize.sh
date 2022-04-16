#!/bin/zsh
set -e

# Optimizer runner definitions
function run_optimizer_single() {
    python3 -u /app/topology-bw-optimizer/src/runner/runner_single.py \
        $1 $2 $3 $4 $5 $6 $7 $8
}

function run_optimizer_group() {
    python3 -u /app/topology-bw-optimizer/src/runner/runner_group.py \
        $1 $2 $3 $4 $5 \
        "/app/optimizer_input/workload/transformer_17B.txt" \
        "/app/optimizer_input/workload/transformer_175B.txt" \
        "/app/optimizer_input/workload/transformer_1T.txt"
}

# Parse Network
case "$1" in
2D)
    network="/app/optimizer_input/network/2d.json";;
3D)
    network="/app/optimizer_input/network/3d.json";;
4D)
    network="/app/optimizer_input/network/4d.json";;
esac
bandwidth="$2"

# Parse Workload
case "$3" in
17B)
    workload="/app/optimizer_input/workload/transformer_17B.txt"
    mp=1
    dp=1024;;
175B)
    workload="/app/optimizer_input/workload/transformer_175B.txt"
    mp=16
    dp=64;;
1T)
    workload="/app/optimizer_input/workload/transformer_1T.txt"
    mp=128
    dp=8;;
esac

# Parse others
bwtarget="$4"
trainingloop="$5"
costmodel="/app/optimizer_input/cost/cost.json"

# Run
case "$3" in
Group)
    run_optimizer_group ${network} ${costmodel} ${bandwidth} ${bwtarget} ${trainingloop};;
*)
    run_optimizer_single ${network} ${costmodel} ${workload} ${bandwidth} ${bwtarget} ${trainingloop} ${mp} ${dp};;
esac
