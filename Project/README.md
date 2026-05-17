# Bioinformatics Final Project 

## Overview

The goal of this project is to compare commensal and pathogenic S.epidermis. Genes specific to pathogenic or commensal function have been selected and will be compared among strains


## Data Input : 

### Strains_cleaned.csv

The input CSV file contains strain metadata with the following columns:
- `Strain` - strain identifier
- `Host source` - source tissue/site
- `host health` - health status
- `accession number` - NCBI RefSeq/GenBank accession (e.g., GCA_011307695.1)
- `type` - strain type classification

### target_sequences 

- Fasta sequences of target genes downloaded from NCBI 


## Step-by-Step Guide

### 1. Download Genomic Sequences and Annotations
**Script:** `fetch_sequences_annotations.sh`

**What it does:**
- Creates micromamba environment with required tools (NCBI E-utilities)
- Reads strain metadata from `Strains_cleaned.csv`
- Fetches genomic FASTA files for each strain using NCBI accession numbers
- Fetches corresponding GFF annotation files
- Organizes files into separate `fasta/` and `gff/` directories

**Output files:**
- `data/sequences_annotations/fasta/` - Genomic sequences (one FASTA per strain)
- `data/sequences_annotations/gff/` - Annotation files (one GFF per strain)
- `data/sequences_annotations/fetch_log.txt` - Detailed download log


### 2. Match Strains to Target Genes
**Script:** `match_sequences.sh`

**What it does:**
- Uses ABRicate to search genomic sequences against target gene databases
- Matches each strain's genome against `target_genes_all/` and `target_genes_ica/` databases
- Filters and outputs clean gene matches
- Generates raw ABRicate results for each strain and gene type

**Output files:**
- `raw_outputs/abricate/` - Raw ABRicate hits for all strains and gene types
- `outputs/abricate/strain_gene_matches_from_raws.tsv` - cleaned version of all hits
- `outputs/GENE_MATCHING_RESULTS.md`- summary of gene matching process 


### 3. Build Presence/Absence Matrix
**Script:** `create_matrix.r`

**What it does:**
- Parses ABRicate output files from `outputs/abricate/`
- Creates binary presence/absence matrix (1 = gene present, 0 = absent)
- Integrates strain metadata from `Strains_cleaned.csv`
- Removes strain without metadata 

**Output files:**
- `outputs/gene_presence_absence_matrix.csv` - strain name + gene presence  
- `outputs/strains_with_genes.csv` - metadata + genes presence


### 4. Analyze Gene Presence Patterns
**Script:** `gene_presence.r`

**What it does:**
- Analyzes gene frequency patterns by host source and strain type
- Calculates gene presence statistics for pathogenic vs commensal strains
- Generates comparative frequency tables

**Output files:**
- `outputs/gene_frequency_by_source.csv` - Gene frequency by host source
- `outputs/gene_frequency_by_type.csv` - Gene frequency by strain type


### 5. Prepare Phylogenetic Tree Data
**Script:** `phylogentic_tree_1.sh`

**What it does:**
- Processes genomic sequences for phylogenetic analysis
- Runs Parsnp for multiple sequence alignment and tree construction
- Generates tree topology and genome comparison data

**Output files:**
- `raw_outputs/parsnp_tree/` - Raw Parsnp output files


### 6. Visualize Tree with Gene Heatmap
**Script:** `plot_tree_with_heatmap.r`

**What it does:**
- Integrates phylogenetic tree with gene presence data
- Creates visualization linking evolutionary relationships to gene presence/absence
- Produces plots showing strain relationships and gene distribution

**Output files:**
- `outputs/parsnp_tree/` - Generated plots and visualizations
  - Phylogenetic tree with heatmap overlay












