#!/usr/bin/env bash
set -u

usage() {
    echo "Usage: $0 LOG_FILE COMMAND [ARGUMENTS...]" >&2
}

if [ "$#" -lt 2 ]; then
    usage
    exit 2
fi

log_file=$1
shift

log_dir=$(dirname -- "$log_file")

# Create only missing paths; do not alter permissions on existing directories.
if [ ! -d "$log_dir" ]; then
    if ! install -d -m 0750 "$log_dir"; then
        echo "ERROR: Could not create log directory: $log_dir" >&2
        exit 1
    fi
fi

if [ ! -e "$log_file" ]; then
    if ! install -m 0640 /dev/null "$log_file"; then
        echo "ERROR: Could not create log file: $log_file" >&2
        exit 1
    fi
fi

if [ ! -f "$log_file" ] || [ ! -w "$log_file" ]; then
    echo "ERROR: Log path is not a writable regular file: $log_file" >&2
    exit 1
fi

if ! exec >> "$log_file" 2>&1; then
    echo "ERROR: Could not open log file: $log_file" >&2
    exit 1
fi

started_at=$(date --iso-8601=seconds)
started_epoch=$(date +%s)
host_name=$(hostname -f 2>/dev/null || hostname)

echo "============================================================"
echo "Started: $started_at"
echo "Host: $host_name"
printf 'Command:'
printf ' %q' "$@"
printf '\n\n'

"$@"
status=$?

finished_epoch=$(date +%s)
finished_at=$(date --iso-8601=seconds)
duration=$((finished_epoch - started_epoch))

echo
echo "Finished: $finished_at"
echo "Duration: $duration seconds"
echo "Exit status: $status"
echo

exit "$status"
