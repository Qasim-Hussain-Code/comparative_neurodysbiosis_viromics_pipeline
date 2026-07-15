# Comparative Neurodysbiosis Viromics Pipeline

A modular viromics workflow for identifying, curating, and profiling metagenome-assembled viral genomes from comparative clinical or experimental cohorts. This pipeline characterizes the structural dynamics and taxonomic composition of viral communities associated with neurodysbiosis phenotypes alongside neurotypical controls.

The workflow uses the Modular Viromics Pipeline (MVP v1.1.5) to orchestrate deep learning-driven viral identification (geNomad), structural quality assessment (CheckV), de novo sequence clustering into viral Operational Taxonomic Units (vOTUs), and competitive read recruitment for differential abundance profiling.

---

## Data Source

This implementation uses shotgun metagenomic data from the Sharon et al. (2019) gnotobiotic mouse model of autism spectrum disorder (ASD). Germ-free mice were colonized with fecal microbiota from human ASD or typically developing (TD) donors, and cecal contents were sequenced on Illumina HiSeq 4000.

| Sample | ENA Accession | Donor | Mouse | Condition Label |
|---|---|---|---|---|
| ASD-colonized | ERR3144321 | A9 (ASD) | Male, cohort 3 | `Neurodysbiosis_Cohort` |
| TD-colonized | ERR3144319 | C4 (TD) | Male, cohort 3 | `Neurotypical_Control` |

Both samples were selected from the same sex and cohort to minimize confounders.

**Study:** Sharon, G. et al. (2019). Human gut microbiota from autism spectrum disorder promote behavioral symptoms in mice. *Cell*, 177(3), 600-618.  
**Data:** ERP113632 (European Nucleotide Archive)

---

## Computational Architecture

The workflow is executed sequentially across three phases covering data provisioning and five core analytical modules.

### Phase 00: Environment Provisioning (`scripts/00_install.sh`)

Creates the isolated Conda environment with all required dependencies (MVP, MEGAHIT, Bowtie2, Samtools, CoverM, geNomad, CheckV) and downloads the geNomad and CheckV reference databases.

### Phase 01: Data Acquisition and Co-Assembly (`scripts/01_provision_data.sh`)

Downloads full-depth paired-end FASTQ files from the European Nucleotide Archive via FTP, then performs de novo metagenomic co-assembly using MEGAHIT with a minimum contig length filter of 1000 bp to limit classification uncertainty in short fragments.

### Phase 02: Core MVP Execution (`scripts/02_execute_mvip.sh`)

Orchestrates the five MVP analytical modules in sequence:

**Module 00 (Setup):** Validates the structural integrity of user-provided metadata manifests and checks raw input files for non-nucleotide characters or duplicate sequence headers.

**Module 01 (Viral Extraction):** Deploys geNomad for gene calling, marker-gene annotation, and neural network-based classification of contigs into chromosome, plasmid, or viral lineages. Leverages CheckV to evaluate genomic completeness, estimate quality tiers, and isolate potential host-contamination flanking regions.

**Module 02 (Filtration):** Integrates coordinate and scoring outputs from both geNomad and CheckV into a unified quality matrix. Isolates high-confidence viral segments and discards truncated or non-viral artifacts.

**Module 03 (Clustering):** Subjects verified viral sequences to all-versus-all BLASTn alignment, clustering at 95% pairwise Average Nucleotide Identity (ANI) across 85% of the shorter sequence to establish non-redundant vOTU representatives. Constructs a Bowtie2 reference index from the representative sequences.

**Module 04 (Read Mapping):** Maps raw metagenomic reads from each cohort library against the vOTU index using Bowtie2 competitive alignment. Deploys CoverM to calculate horizontal coverage and relative abundance profiles.

---

## Directory Structure

```text
.
├── 00_ASSEMBLY_FILES/       # MEGAHIT co-assembly scaffolds (gut_scaffolds.fna)
├── 00_DATABASES/            # Reference libraries for geNomad, CheckV, Pfam, dbAPIS
├── 00_MODIFIED_ASSEMBLY_FILES/  # MVP-reformatted per-sample assemblies
├── 00_READ_FILES/           # Paired-end FASTQ files from ENA
├── 01_GENOMAD/              # geNomad classification output per sample
├── 02_CHECK_V/              # CheckV quality reports and merged matrices
├── 03_CLUSTERING/           # Clustered vOTU FASTA files and quality summaries
├── 04_READ_MAPPING/         # Bowtie2 index, BAM alignments, CoverM tables
├── 05_VOTU_TABLES/          # Consolidated vOTU abundance tables
├── 06_FUNCTIONAL_ANNOTATION/  # geNomad gene annotations and protein sequences
├── envs/                    # Conda environment specification
├── scripts/                 # Pipeline execution scripts
├── metadata.txt             # Tab-delimited sample manifest
└── README.md
```

---

## Input Specifications

### Metadata Manifest (`metadata.txt`)

Tab-delimited tracking file with explicit headers defining sample relationships and absolute directory locations:

```text
Sample_number	Sample	Assembly_Path	Read_Path
1	Neurodysbiosis_Cohort	/absolute/path/to/00_ASSEMBLY_FILES/gut_scaffolds.fna	/absolute/path/to/00_READ_FILES/ERR3144321_1.fastq.gz
2	Neurotypical_Control	/absolute/path/to/00_ASSEMBLY_FILES/gut_scaffolds.fna	/absolute/path/to/00_READ_FILES/ERR3144319_1.fastq.gz
```

### Sequence Contigs

Input assemblies must contain de novo co-assembled metagenomic scaffolds. Sequences shorter than 1000 base pairs are excluded prior to executing the deep learning classifier to limit taxonomic classification uncertainty.

---

## Deployment and Execution

### Prerequisites

A working Conda or Mamba installation is required. All dependencies are managed via the `mvip` environment.

### Full Pipeline Execution

```bash
# Step 1: Provision the environment and databases
chmod +x scripts/*.sh
./scripts/00_install.sh

# Step 2: Download reads and build the co-assembly
./scripts/01_provision_data.sh

# Step 3: Run the MVP viromics pipeline
./scripts/02_execute_mvip.sh
```

---

## Key Output Files

| File | Description |
|---|---|
| `03_CLUSTERING/MVP_03_*Representative*Quality_Summary.tsv` | Non-redundant vOTU quality, completeness, and taxonomy |
| `03_CLUSTERING/MVP_03_*Representative*Sequences.fna` | Representative vOTU nucleotide sequences |
| `04_READ_MAPPING/*/CoverM.tsv` | Per-sample horizontal coverage and abundance profiles |
| `06_FUNCTIONAL_ANNOTATION/MVP_06_*Gene_Annotation*.tsv` | geNomad gene-level functional annotations |
| `06_FUNCTIONAL_ANNOTATION/MVP_06_*Protein_Sequences.faa` | Predicted viral protein sequences |

---

## References

* **MVP:** Modular Viromics Pipeline v1.1.5. [https://github.com/animalcule-millmm/MVP](https://github.com/animalcule-millmm/MVP)
* **geNomad:** Camargo et al., 2023. Identification of mobile genetic elements with geNomad. *Nature Biotechnology*. DOI: 10.1038/s41587-023-01953-y.
* **CheckV:** Nayfach et al., 2021. CheckV assesses the quality and completeness of metagenome-assembled viral genomes. *Nature Biotechnology*. DOI: 10.1038/s41587-020-00774-7.
* **MEGAHIT:** Li et al., 2015. MEGAHIT: an ultra-fast single-node solution for large and complex metagenomics assembly via succinct de Bruijn graph. *Bioinformatics*. DOI: 10.1093/bioinformatics/btv033.
* **Bowtie2:** Langmead and Salzberg, 2012. Fast gapped-read alignment with Bowtie 2. *Nature Methods*. DOI: 10.1038/nmeth.1923.
* **CoverM:** Woodcroft, B. [https://github.com/wwood/CoverM](https://github.com/wwood/CoverM).
* **Sharon et al., 2019:** Human gut microbiota from autism spectrum disorder promote behavioral symptoms in mice. *Cell*, 177(3), 600-618. DOI: 10.1016/j.cell.2019.05.004.