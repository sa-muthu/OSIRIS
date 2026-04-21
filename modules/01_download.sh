#!/usr/bin/env bash

# OSIRIS — Module 01: Download

# Downloads:
#   1. SRA reads for the extinct species
#   2. Reference genome of the closest living relative
#
# Usage:
#   bash modules/01_download.sh config/config.yaml

set -euo pipefail  # exit on error, undefined var, pipe failure

# --- Parse config -------------------------------------------
CONFIG=${1:-"config/config.yaml"}

if [[ ! -f "$CONFIG" ]]; then
    echo "[OSIRIS] ERROR: Config file not found: $CONFIG"
    exit 1
fi

# Read values from YAML (no yq dependency — pure bash parsing)
get_config() {
    grep "^$1:" "$CONFIG" | sed 's/.*: *//' | tr -d '"'
}

SPECIES=$(get_config "species_name")
SRA=$(get_config "sra_accession")
REF_ACC=$(get_config "reference_accession")
REF_NAME=$(get_config "reference_name")
THREADS=$(get_config "threads")

# --- Directories --------------------------------------------
RESULTS="results/${SPECIES}"
RAW="${RESULTS}/01_raw"
REF="${RESULTS}/reference"

mkdir -p "$RAW" "$REF"

# --- Log ----------------------------------------------------
LOG="${RESULTS}/osiris.log"
echo "============================================" | tee -a "$LOG"
echo "OSIRIS Module 01 — Download" | tee -a "$LOG"
echo "Species:   $SPECIES" | tee -a "$LOG"
echo "SRA:       $SRA" | tee -a "$LOG"
echo "Reference: $REF_ACC ($REF_NAME)" | tee -a "$LOG"
echo "Started:   $(date)" | tee -a "$LOG"
echo "============================================" | tee -a "$LOG"

# --- Step 1: Download SRA reads -----------------------------
echo "" | tee -a "$LOG"
echo "[01/02] Downloading SRA reads: $SRA" | tee -a "$LOG"

if [[ -f "${RAW}/${SRA}.fastq.gz" ]]; then
    echo "  → Already downloaded, skipping." | tee -a "$LOG"
else
    # fasterq-dump: faster, skips intermediate .sra file
    # --skip-technical: exclude technical reads
    # --threads: parallel download
    fasterq-dump "$SRA" \
        --outdir "$RAW" \
        --threads "$THREADS" \
        --progress \
        --skip-technical \
        2>&1 | tee -a "$LOG"

    # Compress to save space
    echo "  → Compressing FASTQ..." | tee -a "$LOG"
    gzip "${RAW}/${SRA}.fastq"

    echo "  → Done: ${RAW}/${SRA}.fastq.gz" | tee -a "$LOG"
fi

# Quick read count
READ_COUNT=$(zcat "${RAW}/${SRA}.fastq.gz" | wc -l | awk '{print $1/4}')
echo "  → Total reads: $READ_COUNT" | tee -a "$LOG"

# --- Step 2: Download reference genome ----------------------
echo "" | tee -a "$LOG"
echo "[02/02] Downloading reference genome: $REF_ACC ($REF_NAME)" | tee -a "$LOG"

REF_FASTA="${REF}/${REF_NAME}.fna"

if [[ -f "$REF_FASTA" ]]; then
    echo "  → Already downloaded, skipping." | tee -a "$LOG"
else
    # Download using NCBI datasets CLI
    datasets download genome accession "$REF_ACC" \
        --include genome \
        --filename "${REF}/${REF_NAME}.zip" \
        2>&1 | tee -a "$LOG"

    # Unzip and find the FASTA
    unzip -o "${REF}/${REF_NAME}.zip" -d "${REF}/${REF_NAME}_tmp" \
        2>&1 | tee -a "$LOG"

    # Move FASTA to clean location
    find "${REF}/${REF_NAME}_tmp" -name "*.fna" -exec mv {} "$REF_FASTA" \;

    # Cleanup
    rm -rf "${REF}/${REF_NAME}_tmp" "${REF}/${REF_NAME}.zip"

    echo "  → Done: $REF_FASTA" | tee -a "$LOG"
fi

# Reference stats
REF_SIZE=$(seqkit stats "$REF_FASTA" | tail -1 | awk '{print $5}')
REF_SEQS=$(seqkit stats "$REF_FASTA" | tail -1 | awk '{print $4}')
echo "  → Reference sequences: $REF_SEQS" | tee -a "$LOG"
echo "  → Reference total size: $REF_SIZE bp" | tee -a "$LOG"

# --- Summary ------------------------------------------------
echo "" | tee -a "$LOG"
echo "======================Summary======================" | tee -a "$LOG"
echo "Module 01 complete." | tee -a "$LOG"
echo "Finished: $(date)" | tee -a "$LOG"
echo "Outputs:" | tee -a "$LOG"
echo "  Reads:     ${RAW}/${SRA}.fastq.gz" | tee -a "$LOG"
echo "  Reference: $REF_FASTA" | tee -a "$LOG"
echo "============================================" | tee -a "$LOG"
echo ""
echo "[OSIRIS] Next step: bash modules/02_qc.sh $CONFIG"
