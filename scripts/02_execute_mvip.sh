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

# Environment activation safety check adjusted to your local env name
if [[ "${CONDA_DEFAULT_ENV:-}" != "mvip" ]]; then
    eval "$(conda shell.bash hook)"
    conda activate mvip
fi

echo "--> Executing Module 00: Validating Manifest and Folder Structures"
mvip MVP_00_set_up_MVP -i "$REPO_ROOT" -m metadata.txt --skip_install_databases

echo "--> Executing Module 01: Extracting and Grading Viral Signatures"
mvip MVP_01_run_genomad_checkv -i "$REPO_ROOT" -m metadata.txt --threads "$THREADS"

echo "--> Executing Module 04: Mapping Sequencing Reads to Viral Targets"
mvip MVP_04_do_read_mapping -i "$REPO_ROOT" -m metadata.txt --threads "$THREADS"

echo "============================================================"
echo " Pipeline Processing Complete: Visualizing Folder Matrix   "
echo "============================================================"
ls -l
