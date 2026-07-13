#!/bin/bash
eval conda shell.bash hook

# create conda environment
conda create -n mvip -c conda-forge -c bioconda mvip
conda activate mvip
mvip -h