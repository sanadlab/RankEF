#!/bin/bash

#SBATCH --job-name=train_hard_single
#SBATCH --output=logs/train_hard_single_%j.out
#SBATCH --error=logs/train_hard_single_%j.err
#SBATCH --ntasks=1
#SBATCH --partition=nvidia
#SBATCH --gres=gpu:a100:1
#SBATCH -C 80g
#SBATCH --time=93:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8

# Set up environment
module purge
module load cuda/11.8.0

source /share/apps/NYUAD5/miniconda/3-4.11.0/bin/activate
conda activate /scratch/fr2414/envs/rankef

# Print job info
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "SLURM Job ID: $SLURM_JOB_ID"
nvidia-smi

# Create output directory
mkdir -p checkpoints/hard_model_single

mkdir -p memory_logs

# Run training on single GPU
python train_hard.py \
    --train_path data/train.jsonl \
    --val_path data/val.jsonl \
    --save_dir checkpoints/hard_model_single \
    --model Salesforce/codet5p-770m-py \
    --epochs 5 \
    --lr 1e-4 \
    --batch-size-per-replica 6 \
    --grad-acc-steps 128 \
    --fp16 \
    --log-freq 100 \
    --save-freq 2000 \
    --save_total_limit 3

echo "Job finished at: $(date)"
