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
    find /app/evaluation_input/script_full -type f -name "*.sh" -exec {} \;;;
esac
