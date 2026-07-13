#!/usr/bin/env bash
# =============================================================================
# Pipeline Phase 02: Core Execution of the Modular Viromics Pipeline (MVP)
# =============================================================================
set -euo pipefail

# Determine repository root relative to script position
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

THREADS=4

echo "============================================================"
echo " Starting Modular Viromics Layer: Initiating mvip Run       "
echo "============================================================"

# Environment activation safety check
if [[ "${CONDA_DEFAULT_ENV:-}" != "mvp_env" ]]; then
    eval "$(conda shell.bash hook)"
    conda activate mvp_env
fi

echo "--> Executing Module 00: Validating Manifest and Folder Structures"
mvip module_00 --metadata metadata.txt --working_dir "$REPO_ROOT" --skip_install_databases

echo "--> Executing Module 01: Extracting and Grading Viral Signatures"
# Automatically targets the assembly files listed in your manifest map
mvip module_01 --metadata metadata.txt --working_dir "$REPO_ROOT" --threads "$THREADS"

echo "--> Executing Module 04: Mapping Sequencing Reads to Viral Targets"
# Maps short-read files back to identified viral templates for quantification
mvip module_04 --metadata metadata.txt --working_dir "$REPO_ROOT" --threads "$THREADS"

echo "============================================================"
echo " Pipeline Processing Complete: Visualizing Folder Matrix   "
echo "============================================================"
ls -l
