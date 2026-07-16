[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
# Comparative Neurodysbiosis Metagenomic and Viromics Pipeline

This repository implements a scientifically rigorous, modular viromics analysis pipeline to identify, grade, cluster, and profile viral communities from metagenomic datasets. The target application of this workflow is the comparative study of the gut virome associated with neurodevelopmental conditions, using shotgun metagenomics data from mouse models colonized with human donor microbiota.

## Scientific Context and Study Design

The data utilized in this pipeline originates from the study by Sharon et al. (2019, Cell 177:600-618), which investigates how the gut microbiota of human donors with Autism Spectrum Disorder (ASD) or Typically Developing (TD) controls alter mouse behavior and physiology. Shotgun metagenomic sequencing was performed on cecal contents from gnotobiotic mice to profile the gut microbial community. 

This pipeline focuses on the viral fraction of the metagenome (the virome). The experimental design compares the viral operational taxonomic units (vOTUs) between two distinct cohorts:
1. **Neurodysbiosis Cohort:** Mice colonized with microbiota from ASD human donors (associated with sequencing run accession ERR3144321).
2. **Neurotypical Control:** Mice colonized with microbiota from TD human donors (associated with sequencing run accession ERR3144319).

## Methodological Rigor and Sanity Check

To ensure biological validity, this pipeline enforces strict computational controls:

* **De Novo Co-Assembly:** Rather than mapping metagenomic reads to arbitrary NCBI laboratory reference genomes, a de novo co-assembly is constructed directly from the raw paired end reads using MEGAHIT. This captures the specific, native viral signatures present in the mouse gut community.
* **Rigorous Cohort Mapping:** Reads from the ASD cohort (ERR3144321) and TD cohort (ERR3144319) are mapped back to the assembled contigs to calculate cohort-specific read recruitment. Swapping metadata labels or using unrelated assemblies would result in zero coverage and scientifically invalid conclusions.
* **Clustering Criteria:** Redundant viral predictions are collapsed using BLASTn alignment into non-redundant vOTUs based on standard community benchmarks (95 percent average nucleotide identity over 85 percent alignment fraction of the shorter sequence).

## Pipeline Architecture

The Modular Viromics Pipeline (MVP) coordinates several key bioinformatic tools:

* **Module 00 (Environment and Asset Validation):** Performs pre-flight checks on sequence files and validates metadata integrity.
* **Module 01 (Viral Identification and Grading):** Identifies viral contigs using geNomad to search for viral markers and taxonomic signals. It then estimates genome completeness and quality using CheckV.
* **Module 02 (Filtering):** Removes low-quality or non-viral sequences using custom quality and completeness thresholds.
* **Module 03 (ANI-Based Clustering):** Conducts pairwise BLASTn alignments to cluster viral sequences into non-redundant vOTUs.
* **Module 04 (Read Recruitment):** Indexes the vOTUs with Bowtie2 and recruits raw metagenomic reads to estimate average depth and coverage.
* **Module 05 (Abundance Profiling):** Generates structured vOTU abundance tables using CoverM to compare coverage patterns across cohorts.
* **Module 06 (Functional Annotation):** Annotates viral open reading frames against protein database models to characterize the metabolic potential of the virome.

## Repository Structure

The layout below illustrates the organization of the repository and the purpose of each directory:

```
comparative_neurodysbiosis_viromics_pipeline/
├── .gitignore                          # Excludes raw data while keeping directory structures
├── README.md                           # Documentation of the project
├── metadata.txt                        # Cohort mapping and file paths
├── envs/
│   └── mvp_env.yml                     # Conda environment specification file
├── scripts/
│   ├── 00_install.sh                   # Environment setup and database installation script
│   ├── 01_provision_data.sh            # ENA download and MEGAHIT co-assembly script
│   └── 02_execute_mvip.sh              # Orchestration script for modules 00 to 04
├── 00_READ_FILES/
│   └── README.md                       # Raw FASTQ files (ignored)
├── 00_ASSEMBLY_FILES/
│   └── README.md                       # De novo assembled scaffolds (ignored)
├── 00_MODIFIED_ASSEMBLY_FILES/
│   └── README.md                       # Renamed and filtered contigs (ignored)
├── 00_DATABASES/
│   └── README.md                       # Local geNomad and CheckV databases (ignored)
├── 01_GENOMAD/
│   └── README.md                       # geNomad prediction outputs (ignored)
├── 02_CHECK_V/
│   └── README.md                       # CheckV quality reports (ignored)
├── 03_CLUSTERING/
│   └── README.md                       # ANI-based vOTU clustering outputs (ignored)
├── 04_READ_MAPPING/
│   └── README.md                       # Bowtie2 BAM files and CoverM coverage files (ignored)
├── 05_VOTU_TABLES/
│   └── README.md                       # Abundance and horizontal coverage tables (ignored)
└── 06_FUNCTIONAL_ANNOTATION/
    └── README.md                       # Functional annotation outputs (ignored)
```

## Setup and Execution

To execute this pipeline on your local system, follow these steps:

### 1. Environment Setup
Create the required Conda environment and download the necessary reference databases:
```bash
./scripts/00_install.sh
```

### 2. Metagenomic Assembly
Download the raw shotgun reads from ENA and run the de novo co-assembly:
```bash
./scripts/01_provision_data.sh
```

### 3. Pipeline Run
Activate the environment and execute the pipeline:
```bash
conda activate mvip
./scripts/02_execute_mvip.sh
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
