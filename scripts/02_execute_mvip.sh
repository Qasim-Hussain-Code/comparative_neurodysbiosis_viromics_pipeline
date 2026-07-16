#!/usr/bin/env bash
# =============================================================================
# Pipeline Phase 02: Core Execution of the Modular Viromics Pipeline (MVP)
#
# Study:  Sharon et al. 2019, Cell 177(3):600-618
# Data:   ERP113632 (ENA) -- Mouse cecal shotgun metagenomics
# Samples:
#   ERR3144321 (ASD donor A9, male mouse, cohort 3)  ->  Neurodysbiosis_Cohort
#   ERR3144319 (TD  donor C4, male mouse, cohort 3)  ->  Neurotypical_Control
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

THREADS=4

echo "============================================================"
echo " Starting Modular Viromics Layer: Initiating mvip Run       "
echo "============================================================"

if [[ "${CONDA_DEFAULT_ENV:-}" != "mvip" ]]; then
    eval "$(conda shell.bash hook)"
    conda activate mvip
fi

# ── Pre-flight check: verify the assembly ──
ASSEMBLY="$REPO_ROOT/00_ASSEMBLY_FILES/gut_scaffolds.fna"
if [ ! -f "$ASSEMBLY" ]; then
    echo "ERROR: Assembly file not found at $ASSEMBLY"
    echo "       Run ./scripts/01_provision_data.sh first."
    exit 1
fi

CONTIG_COUNT=$(grep -c "^>" "$ASSEMBLY")
if [ "$CONTIG_COUNT" -lt 10 ]; then
    echo "WARNING: Assembly contains only $CONTIG_COUNT contigs."
    echo "         This may indicate placeholder reference genomes rather"
    echo "         than a genuine de novo metagenomic co-assembly."
    echo "         Consider re-running ./scripts/01_provision_data.sh"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "---> Assembly: $CONTIG_COUNT contigs verified."
echo ""

echo "---> Executing Module 00: Validating Local Verified Reference Assets"
mvip MVP_00_set_up_MVP -i "$REPO_ROOT" -m metadata.txt --skip_install_databases

echo "---> Executing Module 01: Extracting and Grading Viral Signatures"
mvip MVP_01_run_genomad_checkv -i "$REPO_ROOT" -m metadata.txt --threads "$THREADS"

echo "---> Executing Module 02: Merging and Filtering Sequence Summaries"
mvip MVP_02_filter_genomad_checkv -i "$REPO_ROOT" -m metadata.txt

echo "---> Executing Module 03: Clustering Reference Space into Clustered vOTUs"
mvip MVP_03_do_clustering -i "$REPO_ROOT" -m metadata.txt --threads "$THREADS"

echo "---> Executing Module 04: Mapping Sequencing Reads to Clustered vOTUs"
mvip MVP_04_do_read_mapping -i "$REPO_ROOT" -m metadata.txt --threads "$THREADS"

echo "============================================================"
echo " Pipeline Processing Complete                              "
echo "============================================================"
echo ""
echo "Key output files:"
echo "  vOTU quality:   03_CLUSTERING/MVP_03_*Representative*Quality_Summary.tsv"
echo "  vOTU sequences: 03_CLUSTERING/MVP_03_*Representative*Sequences.fna"
echo "  Coverage:       04_READ_MAPPING/*/CoverM.tsv"
echo "  Annotations:    06_FUNCTIONAL_ANNOTATION/MVP_06_*Gene_Annotation*.tsv"