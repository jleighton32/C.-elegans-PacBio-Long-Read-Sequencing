# C.-elegans-PacBio-Long-Read-Sequencing
We performed a PacBio long read sequencing project on fcd-2 C. elegans mutants to look for structural variants. 

This repository documents my process for calling and analyzing structural variants and SNPs in *C. elegans* using PacBio and Illumina data.

## Overview
This project demonstrates:
- Use of SLURM batch scripts for HPC processing
- Variant calling using GATK and SAMtools
- Structural variant filtering and summarization using custom Python scripts
- Statistical analysis and visualization in R


## Folder Structure
- `batch_scripts/`: Bash scripts used to run variant calling steps
- `python_scripts/`: Scripts for filtering and summarizing insertion/deletion data
- `r_scripts/`: Scripts for statistical analysis
- `results_example/`: Example output data tables

---
