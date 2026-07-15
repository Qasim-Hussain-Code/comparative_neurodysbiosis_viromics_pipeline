# Comparative Neurodysbiosis Viromics Pipeline

This repository contains the computational framework designed to systematically identify, curate, and profile metagenome-assembled viral genomes from comparative clinical or experimental cohorts. The pipeline is optimized to characterize the structural dynamics and taxonomic composition of viral communities associated with neurodysbiosis phenotypes alongside neurotypical controls.

Utilizing the core execution architecture of the Modular Viromics Pipeline (MVP v1.1.5), this workflow orchestrates deep learning-driven viral identification, structural quality assessment, de novo sequence clustering, and high-throughput read recruitment to construct a non-redundant reference space of viral Operational Taxonomic Units (vOTUs).

---

## Computational Architecture

The workflow is executed sequentially across five core functional modules to ensure analytical reproducibility and strict quality control.

### Module 00: Infrastructure Initialization

* **Function:** Validates the structural integrity of user-provided metadata manifests and checks raw input files for non-nucleotide characters or duplicate sequence headers.
* **Database Management:** Automatically configures directory networks and verifies the presence of required downstream database keys.

### Module 01: Viral Signature Extraction and Quality Grading

* **Deep Learning Classification:** Deploys geNomad to execute gene calling, marker-gene annotation, and neural network-based classification of nucleotide sequence fragments into chromosome, plasmid, or viral lineages.
* **Completeness Assessment:** Leverages CheckV to evaluate genomic completeness, estimate boundary quality tiers, and isolate potential host-contamination flanking regions in proviral contigs.

### Module 02: Summary Curation and Filtration

* **Matrix Integration:** Blends the coordinate and scoring outputs from both geNomad and CheckV into a unified quality matrix.
* **Sequence Compaction:** Isolates high-confidence viral segments and discards truncated or non-viral artifacts based on user-defined score and length thresholds.

### Module 03: De Novo Clustering and Index Building

* **OTU Delineation:** Subjects verified viral sequences to an all-versus-all BLASTn alignment, clustering them at a 95 percent pairwise Average Nucleotide Identity (ANI) across an 85 percent fraction of the shorter sequence to establish non-redundant vOTU representatives.
* **Index Generation:** Compiles the representative sequences into a consolidated FASTA file and constructs a Bowtie2 reference database.

### Module 04: High-Throughput Read Mapping

* **Competitive Alignment:** Maps raw metagenomic sequencing reads from individual cohort libraries against the centralized vOTU index using Bowtie2.
* **Coverage Profiling:** Deploys CoverM to parse sorted alignment files (BAM format), calculating horizontal coverage parameters and relative abundance profiles for downstream statistical validation.

---

## Directory Structure

The workspace assumes the following organization for programmatic execution:

```text
.
├── 00_ASSEMBLY_FILES/     # Metagenomic co-assembly scaffolds (e.g., gut_scaffolds.fna)
├── 00_DATABASES/          # Reference libraries for geNomad, CheckV, Pfam, and dbAPIS
├── 00_READ_FILES/          # Compressed raw sequencing reads (paired-end FASTQ format)
├── 01_GENOMAD/            # Output directories for geNomad classification steps
├── 02_CHECK_V/            # Quality reports and consolidated cohort data matrices
├── 03_CLUSTERING/         # Clustered vOTU fasta outputs and alignment files
├── 04_READ_MAPPING/       # Bowtie2 index binaries, alignment maps, and CoverM abundance tables
├── metadata.txt           # Tab-delimited file mapping samples to data paths
└── scripts/
    └── 02_execute_mvip.sh # Master automation wrapper script

```

---

## Input Specifications

### 1. Metadata Manifest (`metadata.txt`)

The pipeline parses a strictly formatted, tab-delimited tracking file. This manifest must contain explicit headers defining sample relationships and exact directory locations:

```text
Sample_number	Sample	Assembly_Path	Read_Path
1	Neurodysbiosis_Cohort	/absolute/path/to/00_ASSEMBLY_FILES/gut_scaffolds.fna	/absolute/path/to/00_READ_FILES/Sample1_1.fastq.gz
2	Neurotypical_Control	/absolute/path/to/00_ASSEMBLY_FILES/gut_scaffolds.fna	/absolute/path/to/00_READ_FILES/Sample2_1.fastq.gz

```

### 2. Sequence Contigs

Input assemblies should contain pre-filtered, cross-assembled metagenomic scaffolds. Sequences shorter than 1000 base pairs are generally excluded prior to executing the deep-learning classifier to limit taxonomic classification uncertainty.

---

## Deployment and Execution

### Prerequisites

The computational environment must be managed via Conda. Ensure that all standard dependencies (including Bowtie2, Samtools, CoverM, geNomad, and CheckV) are compiled inside an isolated, active environment layer.

### Pipeline Execution

To execute the baseline analytical track, activate the target environment and launch the automated wrapper script from the root folder directory:

```bash
conda activate mvip
./scripts/02_execute_mvip.sh

```

The script automatically handles cross-module communication, ensures environment stability, updates runtime statistics, and generates concise validation logs upon completing the read recruitment metrics.

---

## References

If utilizing this infrastructure for comparative dataset profiling, please ensure the direct citation of the core computational frameworks integrated within this layer:

* **geNomad:** Camargo et al., 2023. Identification of mobile genetic elements with geNomad. *Nature Biotechnology*. DOI: 10.1038/s41587-023-01953-y.
* **CheckV:** Nayfach et al., 2021. CheckV assesses the quality and completeness of metagenome-assembled viral genomes. *Nature Biotechnology*. DOI: 10.1038/s41587-020-00774-7.
* **Bowtie2:** Langmead and Salzberg, 2012. Fast gapped-read alignment with Bowtie 2. *Nature Methods*. DOI: 10.1038/nmeth.1923.
* **CoverM:** Wood, H. ([https://github.com/wwood/CoverM](https://github.com/wwood/CoverM)).