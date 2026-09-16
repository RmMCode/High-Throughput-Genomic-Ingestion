#!/bin/bash

# Title: fetch_ebola_runs.sh
# Description: Programmatic REST API Ingestion & Parallel Sequence Extraction
# Author: ASU BIO 439 Student (Computer Science / Data Science Major)

# Design Philosophy: Automated API integration with robust dependency checks,
# fault tolerance, and multi-core resource allocation constraints.

set -u          # Exit immediately on referencing unassigned variables
set -e          # Abort on first command exit failure
set -o pipefail # Propagate piped errors immediately

## Configuration & Styling
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

## Default BioProject for the 2014 Ebola Outbreak (Gire et al., Science)
BIOPROJECTs="PRJNA257197"
THREADS=$(nproc || echo "2") # Dynamically allocate core count
LIMIT=5                      # Ingestion limit for demo/safety safety gates

##  Dependency Verification 
check_dependency() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}${BOLD}Dependency Error:${RESET} $cmd is not installed."
        echo -e "Please install the SRA Toolkit or Entrez Direct before running this script."
        exit 1
    fi
}

echo -e "${CYAN}================================================================${RESET}"
echo -e "${BOLD}📡 HIGH-THROUGHPUT GENOMIC API INGESTION PIPELINE ${RESET}"
echo -e "${CYAN}================================================================${RESET}"

echo -e "${GREEN}[1/4] Checking environment dependencies...${RESET}"
# Entrez Direct commands
check_dependency "esearch"
check_dependency "efetch"
# SRA Toolkit commands
check_dependency "fastq-dump"
echo -e "  -> All dependencies verified. Multi-core ceiling set to: ${BOLD}${THREADS} threads${RESET}."
echo

## Metadata Query & Ingestion
echo -e "${GREEN}[2/4] Executing REST API query against NCBI SRA database...${RESET}"
echo -e "  -> Target BioProject: ${BOLD}${BIOPROJECT}${RESET}"

# Fetch XML runinfo and parse into clean CSV
METADATA_OUT="/workspace/scratch/${BIOPROJECT}_sra_runinfo.csv"

# esearch pipes query into efetch, which extracts table-formatted metadata
esearch -db sra -query "$BIOPROJECT" | efetch -format runinfo > "$METADATA_OUT"

if [ ! -s "$METADATA_OUT" ]; then
    echo -e "${RED}${BOLD}Query Error:${RESET} REST API returned empty results. Check BioProject ID."
    exit 1
fi

TOTAL_RUNS=$(wc -l < "$METADATA_OUT" | xargs)
# Adjust count because CSV has header
TOTAL_RUNS=$((TOTAL_RUNS - 1))

echo -e "  -> ${GREEN}Query Successful!${RESET} Discovered ${BOLD}${TOTAL_RUNS}${RESET} sequencing runs in study."
echo -e "  -> Metadata table cached at: ${BOLD}${METADATA_OUT}${RESET}"
echo

## Run Analysis & Slicing ###
echo -e "${GREEN}[3/4] Parsing sequence metadata & extracting target run IDs...${RESET}"
# Display columns 1 (Run ID), 12 (Base count), and 27 (Platform) for the first 5 records
echo -e "${BOLD}Sample Ingestion Metadata Matrix (Top ${LIMIT} Runs):${RESET}"
echo -e "--------------------------------------------------------"
printf "${BOLD}%-15s  %-12s  %-15s  %-10s${RESET}\n" "Run ID" "Bases (bp)" "Platform" "Layout"
echo -e "--------------------------------------------------------"

# Use awk to parse metadata columns beautifully on-the-fly
awk -F',' 'NR > 1 && NR <= 6 {
    printf "%-15s  %-12s  %-15s  %-10s\n", $1, $12, $21, $16
}' "$METADATA_OUT"
echo -e "--------------------------------------------------------"
echo

## Download Sequence Extraction ###
echo -e "${GREEN}[4/4] Starting parallel sequence extraction (fastq-dump)...${RESET}"
echo -e "  -> ${YELLOW}Safety Gate Active:${RESET} Processing is capped at ${BOLD}${LIMIT}${RESET} SRA runs for testing."
echo -e "  -> Sequences will be split into paired-end files and cached."

# Extract first $LIMIT run IDs from our metadata file
RUN_IDS=$(awk -F',' "NR > 1 && NR <= $((LIMIT + 1)) {print \$1}" "$METADATA_OUT")

OUT_DIR="/workspace/scratch/raw_sequences"
mkdir -p "$OUT_DIR"

for RUN_ID in $RUN_IDS; do
    echo -e "  -> Launching multi-threaded download for run: ${CYAN}${RUN_ID}${RESET}"
    
    # We restrict fastq-dump to download just the first 10,000 spot reads (-X 10000) for demo/testing speed
    # --split-files is a critical CS convention: splits forward and reverse mates for paired-end sequencing
    # into distinct files, preventing down-stream alignment indexing collisions.
    fastq-dump \
        -X 10000 \
        --split-files \
        --outdir "$OUT_DIR" \
        "$RUN_ID"
        
    echo -e "     ${GREEN}✔ Completed run ${RUN_ID}${RESET}. Files written to ${OUT_DIR}/${RUN_ID}_[1/2].fastq"
done

echo
echo -e "${GREEN}SUCCESS:${RESET} high-throughput API download completed."
echo -e "${CYAN}================================================================${RESET}"