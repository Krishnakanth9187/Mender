#!/bin/sh

# Script to collect device identity data for Mender.
# Outputs hardware_id read from a text file.

set -ue  # Exit on error and treat unset variables as errors

HARDWARE_ID_FILE="/home/kk/mender/hardware_id.txt"  # File containing the hardware_id

# Check if the hardware_id file exists
if [ -f "$HARDWARE_ID_FILE" ]; then
    hardware_id=$(cat "$HARDWARE_ID_FILE")
    if [ -z "$hardware_id" ]; then
        echo "Error: hardware_id is empty in $HARDWARE_ID_FILE" >&2
        exit 1
    fi
else
    echo "Error: hardware_id file not found at $HARDWARE_ID_FILE" >&2
    exit 1
fi

# Output the hardware_id as the identity
echo "hardware_id=$hardware_id"
