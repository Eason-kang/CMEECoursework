#!/bin/bash
#PBS -l walltime=12:00:00
#PBS -l select=1:ncpus=1:mem=4gb
#PBS -J 1-100

#eval "$(~/miniforge3/bin/conda shell.bash hook)"
#conda activate r413

echo "R is about to run"
cd HPC_2025/code
/rds/general/user/zk425/home/miniforge3/envs/r413/bin/Rscript zk425_HPC_2025_neutral_cluster.R

echo "R has finished running"

