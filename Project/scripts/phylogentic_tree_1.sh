# Install parsnp and harvesttools to build a phylogenetic tree based on core genome alignment


# Activate existing environment
micromamba activate project_bioinfo

# Install Parsnp and HarvestTools in this environment
micromamba install -y -c conda-forge -c bioconda parsnp harvesttools

# Check installation
parsnp --version
harvesttools --help


# Find a good tree root candidate (with complete genome and commensal )
#!/bin/bash

INPUT_DIR="Project/data/sequences_annotations/fasta"
OUTPUT_FILE="Project/outputs/parsnp_tree/genome_contig_counts.tsv"

echo -e "genome_file\tcontig_count" > "$OUTPUT_FILE"

for file in "$INPUT_DIR"/*.fna; do

    filename=$(basename "$file")

    contigs=$(grep -c "^>" "$file")

    echo -e "${filename}\t${contigs}" >> "$OUTPUT_FILE"

done

echo "Contig count table saved to:"
echo "$OUTPUT_FILE"

# Select a candidate genome with a low contig count
# Here I selcted CV94_GCA_002850315.1.fna	1

# Create Parsnp input directory and copy FASTA files
mkdir -p outputs/parsnp_tree

# Run Parsnp with the selected reference genome
parsnp \
  -r Project/data/sequences_annotations/fasta/CV94_GCA_002850315.1.fna \
  -d Project/data/sequences_annotations/fasta \
  -o Project/outputs/parsnp_tree/parsnp_output 

# output files :
