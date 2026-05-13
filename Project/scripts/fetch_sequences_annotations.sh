#!/bin/bash

#' Fetch FASTA sequences and GFF annotations for strains
#' 
#' This script reads strain information from a CSV file and downloads
#' corresponding FASTA sequences and GFF annotations from NCBI using the datasets tool
#' 
#' Requirements: micromamba, datasets (from NCBI), bash


# Configuration
CSV_FILE="../Strains_cleaned.csv"
OUTPUT_DIR="../sequences_annotations"
FASTA_DIR="${OUTPUT_DIR}/fasta"
GFF_DIR="${OUTPUT_DIR}/gff"
LOG_FILE="${OUTPUT_DIR}/fetch_log.txt"
TEMP_DIR="${OUTPUT_DIR}/temp"

# Resume control: set START_FROM=73 to begin at strain 73 (data rows, header excluded)
START_FROM="${START_FROM:-1}" # didn't fully load first time

# GFF-only mode: set GFF_ONLY=true to skip FASTA and only download GFF annotations
GFF_ONLY="${GFF_ONLY:-false}" # didn't work first time 

# Shared micromamba environment for this project
ENV_NAME="project_bioinfo"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize micromamba 
if ! command -v micromamba &> /dev/null; then
    echo -e "${RED}ERROR: micromamba is required but not found.${NC}"
    exit 1
fi

if ! command -v mamba &> /dev/null; then
    echo -e "${YELLOW}Setting up micromamba...${NC}"
    eval "$(micromamba shell hook --shell bash)"
fi

# Create environment 
if ! micromamba env list | awk 'NR>2{print $1}' | grep -qx "$ENV_NAME"; then
    echo -e "${YELLOW}Creating shared micromamba environment: ${ENV_NAME}${NC}"
    micromamba create -n "$ENV_NAME" -c conda-forge -c bioconda ncbi-datasets-cli -y
fi # add NCBI datasets tool for reliable downloads

# Activate environment
micromamba activate "$ENV_NAME"

# Create output directories
mkdir -p "$FASTA_DIR" "$GFF_DIR" "$TEMP_DIR"

# Initialize log file
{
    echo "=== NCBI Fetch Log ==="
    echo "Started: $(date)"
    echo "Using NCBI datasets tool for reliable downloads"
    echo ""
} > "$LOG_FILE"

# Function to log messages
log_message() {
    local message=$1
    echo -e "$message" | tee -a "$LOG_FILE"
}

# Function to fetch FASTA sequence using datasets
fetch_fasta() {
    local accession=$1
    local strain_name=$2
    local output_file="${FASTA_DIR}/${strain_name}_${accession}.fna"
    local temp_dir="${TEMP_DIR}/${strain_name}_${accession}"
    
    log_message "  Fetching FASTA for ${strain_name} (${accession})..."
    
    mkdir -p "$temp_dir"
    
    # Use datasets to download the genome and annotation package
    if datasets download genome accession "$accession" --include genome,gff3 --filename "${temp_dir}/genome.zip" 2>/dev/null; then
        # Extract the ZIP
        if unzip -q -d "$temp_dir" "${temp_dir}/genome.zip" 2>/dev/null; then
            # Find and copy the FASTA file
            local fasta_file=$(find "$temp_dir" -name "*.fna" 2>/dev/null | head -1)
            if [ -n "$fasta_file" ] && [ -s "$fasta_file" ]; then
                cp "$fasta_file" "$output_file"
                log_message "    ${GREEN}✓ Successfully downloaded${NC}"
                rm -rf "$temp_dir"
                return 0
            fi
        fi
    fi
    
    log_message "    ${RED}✗ Failed to download${NC}"
    rm -rf "$temp_dir"
    return 1
}

# Function to fetch GFF annotation using datasets
fetch_gff() {
    local accession=$1
    local strain_name=$2
    local output_file="${GFF_DIR}/${strain_name}_${accession}.gff"
    local temp_dir="${TEMP_DIR}/${strain_name}_${accession}_gff"
    
    log_message "  Fetching GFF for ${strain_name} (${accession})..."
    
    mkdir -p "$temp_dir"
    
    # Use datasets to download the genome and annotation package
    if datasets download genome accession "$accession" --include genome,gff3 --filename "${temp_dir}/genome.zip" 2>/dev/null; then
        if unzip -q -d "$temp_dir" "${temp_dir}/genome.zip" 2>/dev/null; then
            local gff_file=$(find "$temp_dir" -name "*.gff" -o -name "*.gff3" 2>/dev/null | head -1)
            if [ -n "$gff_file" ] && [ -s "$gff_file" ]; then
                cp "$gff_file" "$output_file"
                log_message "    ${GREEN}✓ Successfully downloaded${NC}"
                rm -rf "$temp_dir"
                return 0
            fi
        fi
    fi
    
    log_message "    ${YELLOW}⚠ GFF not available${NC}"
    rm -rf "$temp_dir"
    return 1
}

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    log_message "${RED}ERROR: CSV file not found: $CSV_FILE${NC}"
    exit 1
fi

# Read CSV file and process each strain (skip header)
log_message "${YELLOW}Starting to fetch sequences and annotations...${NC}\n"
log_message "Starting from data row: ${START_FROM}"
if [ "$GFF_ONLY" = "true" ]; then
    log_message "${YELLOW}GFF-ONLY MODE: Skipping FASTA downloads${NC}"
fi

# Count total lines
total_strains=$(tail -n +2 "$CSV_FILE" | wc -l)
fasta_success=0
gff_success=0
current=0

# Process each strain
data_row=0
while IFS=';' read -r strain host_source host_health accession type; do
    data_row=$((data_row + 1))

    if [ "$data_row" -lt "$START_FROM" ]; then
        continue
    fi

    current=$((current + 1))
    
    # Trim whitespace
    strain=$(echo "$strain" | xargs)
    accession=$(echo "$accession" | xargs)
    
    log_message "\n--- Processing strain ${current}/${total_strains} ---"
    log_message "Strain: $strain"
    log_message "Accession: $accession"
    
    # Fetch FASTA (unless GFF_ONLY mode)
    if [ "$GFF_ONLY" != "true" ]; then
        if fetch_fasta "$accession" "$strain"; then
            fasta_success=$((fasta_success + 1))
        else
            # Stop on first FASTA error for debugging when starting from the first strain
            if [ "$START_FROM" -eq 1 ] && [ $current -eq 1 ]; then
                log_message "${RED}ERROR: First FASTA download failed. Stopping for debugging.${NC}"
                log_message "Command to debug: datasets download genome accession $accession"
                micromamba deactivate
                exit 1
            fi
        fi
    fi

    # Fetch GFF
    if fetch_gff "$accession" "$strain"; then
        gff_success=$((gff_success + 1))
    fi
    
    # Add small delay to avoid rate limiting
    sleep 0.5
    
done < "$CSV_FILE"

# Final summary
{
    echo ""
    echo "=== FETCH SUMMARY ==="
    echo "Total strains processed: ${total_strains}"
    echo "Successful FASTA downloads: ${fasta_success}"
    echo "Successful GFF downloads: ${gff_success}"
    echo "FASTA files: ${FASTA_DIR}"
    echo "GFF files: ${GFF_DIR}"
    echo "Log file: ${LOG_FILE}"
    echo "Finished: $(date)"
} | tee -a "$LOG_FILE"

# Count actual files created
fasta_count=$(ls -1 "${FASTA_DIR}"/*.fna 2>/dev/null | wc -l)
gff_count=$(ls -1 "${GFF_DIR}"/*.gff 2>/dev/null | wc -l)

log_message "\n${GREEN}Actual files created:${NC}"
log_message "  FASTA files: ${fasta_count}"
log_message "  GFF files: ${gff_count}"

# Clean up temporary directory
rm -rf "$TEMP_DIR"

# Deactivate environment
micromamba deactivate

echo -e "\n${GREEN}Done!${NC}"
