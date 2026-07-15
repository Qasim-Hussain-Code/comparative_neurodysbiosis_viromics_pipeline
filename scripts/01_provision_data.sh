#!/usr/bin/env bash
# =============================================================================
# Pipeline Phase 01: Data Acquisition and De Novo Co-Assembly
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

READ_DIR="$REPO_ROOT/00_READ_FILES"
ASSEMBLY_DIR="$REPO_ROOT/00_ASSEMBLY_FILES"
THREADS=4
MIN_CONTIG_LEN=1000

mkdir -p "$READ_DIR" "$ASSEMBLY_DIR"

echo "============================================================"
echo " Phase 01: Data Acquisition from ENA                        "
echo "============================================================"

# ── 1. Download full-depth paired-end reads from ENA FTP ──

# ERR3144321: ASD donor A9-M3 (~1.2M reads, ~209 MB total)
if [ ! -f "$READ_DIR/ERR3144321_1.fastq.gz" ]; then
    echo "---> Downloading ERR3144321 R1 (ASD, A9-M3)"
    wget -q --show-progress -O "$READ_DIR/ERR3144321_1.fastq.gz" \
        "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR314/001/ERR3144321/ERR3144321_1.fastq.gz"
else
    echo "---> ERR3144321 R1 already present. Skipping."
fi

if [ ! -f "$READ_DIR/ERR3144321_2.fastq.gz" ]; then
    echo "---> Downloading ERR3144321 R2 (ASD, A9-M3)"
    wget -q --show-progress -O "$READ_DIR/ERR3144321_2.fastq.gz" \
        "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR314/001/ERR3144321/ERR3144321_2.fastq.gz"
else
    echo "---> ERR3144321 R2 already present. Skipping."
fi

# ERR3144319: TD donor C4-M3 (~983K reads, ~180 MB total)
if [ ! -f "$READ_DIR/ERR3144319_1.fastq.gz" ]; then
    echo "---> Downloading ERR3144319 R1 (TD, C4-M3)"
    wget -q --show-progress -O "$READ_DIR/ERR3144319_1.fastq.gz" \
        "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR314/009/ERR3144319/ERR3144319_1.fastq.gz"
else
    echo "---> ERR3144319 R1 already present. Skipping."
fi

if [ ! -f "$READ_DIR/ERR3144319_2.fastq.gz" ]; then
    echo "---> Downloading ERR3144319 R2 (TD, C4-M3)"
    wget -q --show-progress -O "$READ_DIR/ERR3144319_2.fastq.gz" \
        "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR314/009/ERR3144319/ERR3144319_2.fastq.gz"
else
    echo "---> ERR3144319 R2 already present. Skipping."
fi

echo ""
echo "---> Read download complete. Verifying file integrity:"
for f in "$READ_DIR"/ERR*.fastq.gz; do
    reads=$(zcat "$f" | awk 'END{print NR/4}')
    echo "    $(basename "$f"): $reads reads"
done

echo ""
echo "============================================================"
echo " Phase 01b: De Novo Metagenomic Co-Assembly via MEGAHIT     "
echo "============================================================"

# ── 2. Activate environment if needed ──
if [[ "${CONDA_DEFAULT_ENV:-}" != "mvip" ]]; then
    eval "$(conda shell.bash hook)"
    conda activate mvip
fi

# ── 3. Run MEGAHIT co-assembly ──
MEGAHIT_OUT="$REPO_ROOT/megahit_coassembly"

if [ -f "$ASSEMBLY_DIR/gut_scaffolds.fna" ]; then
    echo "---> Assembly already exists at $ASSEMBLY_DIR/gut_scaffolds.fna"
    echo "    To force reassembly, delete this file and re-run."
else
    echo "---> Running MEGAHIT co-assembly (threads=$THREADS, min-contig=$MIN_CONTIG_LEN)"

    # Remove stale MEGAHIT output directory if present (MEGAHIT refuses to overwrite)
    rm -rf "$MEGAHIT_OUT"

    megahit \
        -1 "$READ_DIR/ERR3144321_1.fastq.gz","$READ_DIR/ERR3144319_1.fastq.gz" \
        -2 "$READ_DIR/ERR3144321_2.fastq.gz","$READ_DIR/ERR3144319_2.fastq.gz" \
        --min-contig-len "$MIN_CONTIG_LEN" \
        -t "$THREADS" \
        -o "$MEGAHIT_OUT"

    # Copy final contigs to the expected location
    cp "$MEGAHIT_OUT/final.contigs.fa" "$ASSEMBLY_DIR/gut_scaffolds.fna"

    echo ""
    echo "---> Assembly statistics:"
    contigs=$(grep -c "^>" "$ASSEMBLY_DIR/gut_scaffolds.fna")
    total_bp=$(grep -v "^>" "$ASSEMBLY_DIR/gut_scaffolds.fna" | tr -d '\n' | wc -c)
    echo "    Total contigs (>= ${MIN_CONTIG_LEN} bp): $contigs"
    echo "    Total assembly length: $total_bp bp"
fi

echo ""
echo "============================================================"
echo " Data provisioning complete.                                "
echo "============================================================"
