#!/bin/bash

#SBATCH --job-name=rerun_construction
#SBATCH --output=rerun_construction_%A_%a.out
#SBATCH --error=rerun_construction_%A_%a.err
# The --array directive is now set when submitting the job.
# Example: sbatch --array=0-28 --export=ALL,RANGES_STR="25-138,262-277,..." slurm_generate_rerun.sh
#SBATCH --ntasks=1
#SBATCH --partition=nvidia
#SBATCH --gres=gpu:1

#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=2

# Set up
module purge
module load cuda/11.8.0

source /share/apps/NYUAD5/miniconda/3-4.11.0/bin/activate

# Activate the conda environment
conda activate /scratch/fr2414/envs/rankef

if [ -z "$RANGES_STR" ]; then
    echo "Error: RANGES_STR environment variable is not set."
    echo "Please export RANGES_STR as a comma-separated string of ranges."
    exit 1
fi

# Remove potential leading/trailing single quotes from RANGES_STR
RANGES_STR=$(echo "$RANGES_STR" | sed "s/^'//;s/'$//")

# Convert the comma-separated string of ranges into a bash array
IFS=',' read -r -a RANGES <<< "$RANGES_STR"

echo "Total ranges available: ${#RANGES[@]}"

# Get the range for the current job
CURRENT_RANGE=${RANGES[${SLURM_ARRAY_TASK_ID}]}

# Parse start and end index from the range string
START_INDEX=$(echo $CURRENT_RANGE | cut -d'-' -f1)
END_INDEX=$(( $(echo $CURRENT_RANGE | cut -d'-' -f2) + 1 ))

# print for debugging
echo "Current range: ${CURRENT_RANGE}, Start: ${START_INDEX}, End: ${END_INDEX}"

mkdir -p memory_logs

# Start memory logging in the background
(while true; do
    ram_info=$(free -m | awk '/^Mem:/ {print $3, $2}')
    read ram_used ram_total <<< "$ram_info"
    vram_info=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits)
    echo "$(date): RAM Used: ${ram_used}MB / ${ram_total}MB, VRAM: $vram_info" >> memory_logs/memory_usage_rerun_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log
    sleep 1
done) &
MONITOR_PID=$!

echo "Running job ${SLURM_ARRAY_TASK_ID} for range ${START_INDEX}-${END_INDEX}"

python generate.py \
  --test_path data/apps/train \
  --temperature 0.8 \
  --num_seqs_per_iter 50 \
  --output_path dataset_construction \
  --model_path "Salesforce/codet5p-770m-py" \
  --start ${START_INDEX} \
  --end ${END_INDEX}

# Stop the monitoring process
kill $MONITOR_PID
