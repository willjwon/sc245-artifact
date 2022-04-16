#!/bin/zsh
set -e

# Parse command line arguments
case "$1" in
small)
    /app/evaluation_input/script_small/dgx.sh
    /app/evaluation_input/script_small/perf.sh
    /app/evaluation_input/script_small/perfpercost.sh
    /app/evaluation_input/script_small/equal.sh;;
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
