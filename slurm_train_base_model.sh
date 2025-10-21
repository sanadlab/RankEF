#!/bin/bash

#SBATCH --job-name=train_base_model
#SBATCH --output=train_base_model_%j.out
#SBATCH --error=train_base_model_%j.err
#SBATCH --ntasks=1                      # Number of tasks
#SBATCH --partition=nvidia              # Partition name
#SBATCH --gres=gpu:a100:1                    
#SBATCH -C 80g
#SBATCH --time=01:00:00                 
#SBATCH --mem=64G                      
#SBATCH --cpus-per-task=32              

# Set up
module purge
module load cuda/11.8.0

source /share/apps/NYUAD5/miniconda/3-4.11.0/bin/activate

# Activate the conda environment
conda activate /scratch/fr2414/envs/rankef

# Verify memory allocation
echo "SLURM allocated memory: $SLURM_MEM_PER_NODE MB"

# Run the training script with DeepSpeed
# Start memory logging in the background
(while true; do
    # Log RAM usage (used and total memory in MB)
    ram_info=$(free -m | awk '/^Mem:/ {print $3, $2}')
    read ram_used ram_total <<< "$ram_info"
    
    # Log GPU VRAM usage (used and total memory in MB)
    vram_info=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits)
    vram_used=$(echo "$vram_info" | cut -d',' -f1 | xargs)
    vram_total=$(echo "$vram_info" | cut -d',' -f2 | xargs)

    echo "$(date): RAM Used: ${ram_used}MB / ${ram_total}MB, VRAM Used: ${vram_used}MB / ${vram_total}MB" >> memory_usage.log
    sleep 0.5
done) &
MONITOR_PID=$!

# OPTIMIZED: Multi-GPU training with torchrun
# All optimization parameters are passed explicitly here for clarity
python \
    train_base_model.py \
    --train-path data/apps/train \
    --save_dir steps \
    --model codet5p-770m-py

# Stop the monitoring process
kill $MONITOR_PID
