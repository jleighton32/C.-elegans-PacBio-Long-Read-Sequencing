# Workflow Notes: C. elegans Variant Calling and Structural Variation Analysis

This document records my step-by-step process for preparing, running, and analyzing variant calling in C. elegans using batch scripts, conda environments, and downstream statistical analyses.

---

## 🧩 Overview
The workflow involves:

1. Creating conda environments for variant calling
2. Running batch scripts on a SLURM cluster
3. Using GATK, SAMtools, and other tools for SNP and indel calling
4. Generating summary tables
5. Performing downstream analysis with Python and R

---

## Environment Setup
### Create and activate a conda environment

### Install Necessary packages
conda install -c bioconda minimap2 pbtk
minimap2 -h
pbindex -h

## Convert from PacBio BAM files to normal BAM files: 
### sbatch pacbiobam_to_bam.sh

##Structural Variant and SNP analysis
### Create and activate a conda environment
### sbatch run_gatk.sh
### Check output files
  ce_filtered_snps_count.vcf
  ce_filtered_indels_count.vcf

## Summarize variant counts per sample
  Navigate to results directory 
  find . -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort -V > samples
  while read SAMPLE; do
    indels=$(cat $SAMPLE/gatk/${SAMPLE}_ce_filtered_indels_count.vcf)
    snps=$(cat $SAMPLE/gatk/${SAMPLE}_ce_filtered_snps_count.vcf)
    echo -e "$SAMPLE\t$indels\t$snps" >> gatk_variants_count
    done < samples
### Navigate to gatk_variants_count to visualize counts per sample in table format

## Python statiscial analysis
### Create and activate an environemnt 
### Install necessary packages 
### Run the pscript indels_stats.py
  For filtering variants ≥100 bp:
  python indels_stats.py input_indels sample_id_to_name.tsv 100
### Repeat for other thresholds of interest 

## Annotate with SnpEff to parse out data of interest
### Create an environment 
### Install seaborn library
### Run script
  indels_stats.py 

## Annotate variants above a certain threshold- gene, gene description, size etc. 
### Start and activate a conda environment 
### Run the bscript 
  sbatch indels_summary.sh
