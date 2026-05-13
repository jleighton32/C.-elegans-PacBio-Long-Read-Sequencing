#!/usr/bin/env bash
#SBATCH --job-name=sniffles2_20samples
#SBATCH --partition=cpu
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH --time=48:00:00
#SBATCH --output=sniffles2_%j.out

set -euo pipefail


# Load Conda
module load conda/latest
source $(conda info --base)/etc/profile.d/conda.sh

# Activate Sniffles2 environment
conda activate sniffles2
sniffles --version


# Base directory containing all sample directories with sorted BAMs
BASE_DIR="/work/pi_nhowlett_uri_edu/jessie/New-All-20-Bam"

# Reference genome FASTA (must be uncompressed and indexed)
REF="/work/pi_nhowlett_uri_edu/jessie/reference/WBce1235_genomic.fna"

# Output directory (will be created if it does not exist)
OUT_DIR="/work/pi_nhowlett_uri_edu/jessie/sniffles/per_sample"

THREADS=8
mkdir -p "$OUT_DIR"


# SAMPLE LIST


SAMPLES=(
  1-bc2065  2-bc2066  3-bc2067  4-bc2068  5-bc2069
  6-bc2070  7-bc2071  8-bc2072  9-bc2073  10-bc2074
  11-bc2075 12-bc2076 13-bc2077 14-bc2078 15-bc2079
  16-bc2080 17-bc2081 18-bc2082 19-bc2083 20-bc2084
)

# STEP 1: PER-SAMPLE SV DISCOVERY


echo "▶ Step 1: Running Sniffles2 per sample"

for SAMPLE in "${SAMPLES[@]}"; do
    BAM="${BASE_DIR}/${SAMPLE}/${SAMPLE}_ce_sorted.bam"
    VCF="${OUT_DIR}/${SAMPLE}.sniffles.vcf.gz"

    [[ -f "$BAM" ]] || { echo "❌ Missing $BAM"; exit 1; }

    echo "  → $SAMPLE"

    sniffles \
        --input "$BAM" \
        --reference "$REF" \
        --vcf "$VCF" \
        --threads "$THREADS" \
        --output-rnames
done

echo "✅ Per-sample Sniffles2 complete"