# RankEF

## Custom Additions
Useful things created while recreating the steps to produce a RankEF model.

To generate code samples:
- `slurm_generate.sh`: SLURM script to generate all the code samples. As every task is independent, it divides them into chunks so that we don't have to wait for a long continuous amount of time to be available. 

Sometimes, some generations may be missing because SLURM jobs were terminated or simply some other error:
- `missing_rerun.sh`: sets up the appropriate variables and submits SLURM jobs that will be in charge to generate code samples only for the missing ids.
- `missing.sh`: computes the missing ranges of missing ids, i.e. ids for which code samples are still not generated (`missing_rerun.sh` makes use of it; normally not executed manually).
- `slurm_generate_rerun.sh`: SLURM script that will launch the necessary jobs. Some variables need to be defined before running this script. As such, it is not intended to be executed manually (`missing_rerun.sh` takes care of it and executes this script appropriately).

To compress/extract the code samples (directory `dataset_construction`):
- `compress_or_extract.sh`: If you pass a directory name, e.g. `dataset_construction`, it compresses it. If it's already compressed, e.g. `dataset_construction.tar.xz` and you pass it, the script will extract it.

===============================================

## Installation
The code requires some dependencies as specified in `requirements.txt`. Please follow the relevant libraries to install or run: 

```
pip install -r requirements.txt
```
We are using transformers version 4.33.1, make sure you install the same version as us!

## 1. Data Construction
### Dataset
You can download the APPS dataset [here](https://github.com/hendrycks/apps) to finetune base models.
### Finetune Base Models
First fine tune the base models on the APPS dataset by running the following code:
```
python train_base_model.py
```
### Sample Code Candidates
The fine-tuned model was then used to sample code candidates for subsequent construction of RankEF's dataset. Run the following code:
```
python generate.py
```
### Obtain Execution Feedback
Obtain Execution Feedback to build RankEF dataset by runing:
```
cd metric
bash test_one_solution.sh
```
## 2. Train RankEF
We take three multi-task training approaches to train RankEF by runing:

Hard Parameter Sharing
```
python train_hard.py
```
Soft Parameter Sharing
```
python train_soft.py
```
Intermediate Fine-tuning(INF)
```
python train_gen.py
python train_encoder.py
```
## 3. Rank Code Candidates
Finally, using RankEF to rank the code candidates
```
python test_RankEF.py
```
