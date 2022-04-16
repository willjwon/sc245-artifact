#!/bin/zsh
set -e

# Run script
function plot_small {
    python3 -u /app/plotter/plot_small/$1.py /output/small /output/graph_small
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
        echo "small, fig15";;
    esac;;
full)
    case "$2" in
    fig12)
        echo "full, fig12";;
    fig13)
        echo "full, fig13";;
    fig14)
        echo "full, fig14";;
    fig15)
        echo "full, fig15";;
    esac;;
esac
