#!/bin/zsh
set -e

# Run script
function plot_small {
    python3 -u /app/plotter/plot_small/plot/$1.py /output/small /output/graph_small
}

function plot_full {
    python3 -u /app/plotter/plot_full/plot/$1.py /output/full /output/graph_full
}

# Parse command line arguments
case "$1" in
small)
    case "$2" in
    fig12)
        plot_small plot_small_perf;;
    fig13)
        plot_small plot_small_cost;;
    fig14)
        plot_small plot_small_perfpercost;;
    fig15)
        echo "Fig 15 doesn't support small setup";;
    esac;;
full)
    case "$2" in
    fig12)
        plot_full plot_perf;;
    fig13)
        plot_full plot_cost;;
    fig14)
        plot_full plot_perf_per_cost;;
    fig15)
        plot_full plot_group;;
    esac;;
esac
