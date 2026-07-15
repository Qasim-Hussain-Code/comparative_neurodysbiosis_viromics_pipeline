#!/usr/bin/env bash
# =============================================================================
# Pipeline Phase 00: Environment Provisioning
# Installs the Modular Viromics Pipeline (MVP) and MEGAHIT assembler into an
# isolated Conda environment, then downloads the required geNomad and CheckV
# reference databases.
# =============================================================================
set -euo pipefail

ENV_NAME="mvip"

echo "============================================================"
echo " Phase 00: Provisioning Computational Environment           "
echo "============================================================"

# ── 1. Create or update Conda environment ──
if conda env list | grep -qw "$ENV_NAME"; then
    echo "---> Environment '$ENV_NAME' already exists. Skipping creation."
else
    echo "---> Creating Conda environment: $ENV_NAME"
    conda create -y -n "$ENV_NAME" -c bioconda -c conda-forge \
        python=3.10 \
        mvip \
        megahit \
        sra-tools=3.1.1
fi

eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

echo "---> Active environment: $CONDA_DEFAULT_ENV"
echo "---> Python: $(python --version)"
echo "---> MEGAHIT: $(megahit --version 2>&1 | head -1)"

# ── 2. Install MVP reference databases ──
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB_DIR="$REPO_ROOT/00_DATABASES"
mkdir -p "$DB_DIR"

if [ ! -d "$DB_DIR/genomad_db" ] || [ -z "$(ls -A "$DB_DIR/genomad_db" 2>/dev/null)" ]; then
    echo "---> Downloading geNomad database to $DB_DIR"
    genomad download-database "$DB_DIR"
else
    echo "---> geNomad database already present. Skipping."
fi

if [ ! -d "$DB_DIR/checkv-db-v1.5" ] || [ -z "$(ls -A "$DB_DIR/checkv-db-v1.5" 2>/dev/null)" ]; then
    echo "---> Downloading CheckV database to $DB_DIR"
    checkv download_database "$DB_DIR"
else
    echo "---> CheckV database already present. Skipping."
fi

echo "============================================================"
echo " Environment provisioning complete.                         "
echo "============================================================"
