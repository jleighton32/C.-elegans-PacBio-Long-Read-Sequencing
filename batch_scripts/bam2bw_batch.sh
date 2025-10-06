#!/bin/bash
#SBATCH --partition=uri-cpu,cpu
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --job-name=bam2bw
#SBATCH --output=/work/pi_nhowlett_uri_edu/jessie/bscripts/run/bam2bw_%J.out

# Go to working directory
cd /work/pi_nhowlett_uri_edu/jessie

# ✅ Activate your virtual environment here
source $HOME/deeptools-venv/bin/activate

# Define input and output directories
INPUT_DIR=/work/pi_nhowlett_uri_edu/jessie/New-All-20-Bam
OUTPUT_DIR=/work/pi_nhowlett_uri_edu/jessie/bigwigs

mkdir -p $OUTPUT_DIR

# Loop through all 20 BAM files in their subdirectories
for bamfile in $INPUT_DIR/*/*_ce_sorted.bam
do
    sample=$(basename "$bamfile" _ce_sorted.bam)
    bamCoverage -b "$bamfile" -o "$OUTPUT_DIR/${sample}.bw"
done

