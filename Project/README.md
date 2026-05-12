# Bioinfo Project 

## Overview

The goal of this project is to compare commensal and pathogenic S.epidermis. Genes specific to pathogenic or commensal function have been selected and will be compared among strsains

## Project Structure

```
Project/
├── README.md                    # This file
├── Strains_cleaned.csv         # Input: strain metadata with NCBI accessions
├── scripts/
│   └── fetch_sequences_annotations.sh   # Main script to fetch sequences and annotations
└── sequences_annotations/      # Output directory (created by script)
    ├── fasta/                  # Downloaded FASTA sequence files
    ├── gff/                    # Downloaded GFF annotation files
    └── fetch_log.txt           # Detailed fetch log
```


## Data Input

### Strains_cleaned.csv

The input CSV file contains strain metadata with the following columns:
- `Strain` - strain identifier
- `Host source` - source tissue/site
- `host health` - health status
- `accession number` - NCBI RefSeq/GenBank accession (e.g., GCA_011307695.1)
- `type` - strain type classification


## Downloading sequences 

### Run

```bash
cd Project/scripts
bash fetch_sequences_annotations.sh
```

### What the Script Does

1. Creates micromamba environment
2. Creates output directories :  Organizes FASTA and GFF files separately
3. Fetches sequences : Downloads genomic FASTA files using `efetch`
4. Fetches annotations :  Downloads GFF annotation files using `efetch`
5. output fasta and gff file 


## match existing gene sequences to download strain FASTA 

### download fasta for target gene 
On NCBI find target gene sequence and download on vscode 





