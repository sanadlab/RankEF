#!/bin/bash

# This script is a wrapper to submit the slurm_generate_rerun.sh job.
# It gets a comma-separated list of ranges by running "bash missing.sh".

# Get the directory of the current script to locate missing.sh
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Getting ranges from missing.sh..."
RANGES_STR=$(bash "${SCRIPT_DIR}/missing.sh")

if [ -z "$RANGES_STR" ]; then
    echo "Error: missing.sh did not return any ranges."
    exit 1
fi

# Convert the comma-separated string of ranges into a bash array to count them
IFS=',' read -r -a RANGES_ARRAY <<< "$RANGES_STR"

# Get the number of ranges
NUM_RANGES=${#RANGES_ARRAY[@]}

if [ "$NUM_RANGES" -eq 0 ]; then
    echo "Error: No ranges provided."
    exit 1
fi

# Calculate the slurm array index range (0 to N-1)
SLURM_ARRAY_RANGE="0-$((NUM_RANGES - 1))"

echo "Submitting job with ${NUM_RANGES} tasks for ranges: ${RANGES_STR}"
echo "Slurm array range: ${SLURM_ARRAY_RANGE}"

# Get the directory of the current script to locate slurm_generate_rerun.sh
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Submit the slurm job
sbatch --array=${SLURM_ARRAY_RANGE} \
       --export=ALL,RANGES_STR="'${RANGES_STR}'" \
       "${SCRIPT_DIR}/slurm_generate_rerun.sh"

exit 1

echo "Job submitted."
