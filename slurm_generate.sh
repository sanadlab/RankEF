#!/bin/bash

#SBATCH --job-name=dataset_construction
#SBATCH --output=dataset_construction_%A_%a.out
#SBATCH --error=dataset_construction_%A_%a.err
#SBATCH --array=0-35
#SBATCH --ntasks=1
#SBATCH --partition=nvidia
#SBATCH --gres=gpu:1

#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8

# Set up
module purge
module load cuda/11.8.0

source /share/apps/NYUAD5/miniconda/3-4.11.0/bin/activate

# Activate the conda environment
conda activate /scratch/fr2414/envs/rankef

# Calculate start and end for this job
TOTAL_ITEMS=5000
NUM_JOBS=36
BASE_ITEMS_PER_JOB=$((TOTAL_ITEMS / NUM_JOBS))
REMAINDER=$((TOTAL_ITEMS % NUM_JOBS))
TASK_ID=${SLURM_ARRAY_TASK_ID}

if [ $TASK_ID -lt $REMAINDER ]; then
    START_INDEX=$((TASK_ID * (BASE_ITEMS_PER_JOB + 1)))
    END_INDEX=$((START_INDEX + BASE_ITEMS_PER_JOB + 1))
else
    START_INDEX=$((REMAINDER * (BASE_ITEMS_PER_JOB + 1) + (TASK_ID - REMAINDER) * BASE_ITEMS_PER_JOB))
    END_INDEX=$((START_INDEX + BASE_ITEMS_PER_JOB))
fi

# Ensure the last job doesn't go over the total number of items
if [ $TASK_ID -eq $((NUM_JOBS - 1)) ]; then
    END_INDEX=$TOTAL_ITEMS
fi

mkdir -p memory_logs

# Start memory logging in the background
(while true; do
    ram_info=$(free -m | awk '/^Mem:/ {print $3, $2}')
    read ram_used ram_total <<< "$ram_info"
    vram_info=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits)
    echo "$(date): RAM Used: ${ram_used}MB / ${ram_total}MB, VRAM: $vram_info" >> memory_logs/memory_usage_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.log
    sleep 1
done) &
MONITOR_PID=$!

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
