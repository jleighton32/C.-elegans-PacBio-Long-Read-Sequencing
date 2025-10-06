#!/bin/bash
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --time=05:00:00
#SBATCH --array=1%1
#SBATCH --output=slurm_%A_%a.out
#SBATCH -p uri-cpu,cpu

cd /project/pi_nhowlett_uri_edu/Celegans_PacBio_CNV_2025/20-Demux/All-20-Bam
module load conda/latest
module load samtools/1.19.2

source activate pbtk-env
conda activate /work/pi_nhowlett_uri_edu/jessie/conda-envs/variant-calling-env
# get job array index value
AR=$(($SLURM_ARRAY_TASK_ID))

OUTPUT_PATH=/work/pi_nhowlett_uri_edu/jessie/New-All-20-Bam

# get a pacbio bam file and its prefix
PACBIOBAM=$(find ~+ -name "*.bam" | sort -V | head -n $AR | tail -n 1)
PACBIOBAM_PFX=$(echo $PACBIOBAM | rev | cut -f1 -d"/" | rev | cut -f1 -d".")

# update and create output directory
OUTPUT_PATH=$OUTPUT_PATH/$PACBIOBAM_PFX
mkdir -p $OUTPUT_PATH

# create index to access reads in bam file (the index will be create in the current working directory)
pbindex $PACBIOBAM --num-threads $SLURM_CPUS_ON_NODE

# convert bam to fastq
bam2fastq -o $OUTPUT_PATH/$PACBIOBAM_PFX $PACBIOBAM --num-threads $SLURM_CPUS_ON_NODE

# align reads to C. elegans genome --> ~30 minutes with 100GB and 16 cores
INPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX).fastq.gz
OUTPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce.sam
minimap2 -a /project/pi_nhowlett_uri_edu/Celegans_PacBio_CNV_2025/GCF_000002985.6_WBcel235_genomic.fna.gz $INPUT -o $OUTPUT -t $SLURM_CPUS_ON_NODE

# convert sam file to bam file
INPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce.sam
OUTPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce.bam
samtools view -@ $SLURM_CPUS_ON_NODE -Sb -o $OUTPUT $INPUT

# sort bam file (required to prepare bam file for indexing)
INPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce.bam
OUTPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce_sorted.bam
samtools sort $INPUT -o $OUTPUT

# create index for bam file
INPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce_sorted.bam
OUTPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce_sorted.bai
samtools index -b $INPUT -o $OUTPUT

# reset the environment to use deepTools
#module unload SAMtools/1.16.1-GCC-11.3.0
#module unload minimap2/2.24-GCCcore-11.3.0
#module load deepTools/3.3.1-intel-2019b-Python-3.7.4

# convert file from bam format to bigwig format
#INPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce_sorted.bam
#OUTPUT=$(echo $OUTPUT_PATH/$PACBIOBAM_PFX)_ce_sorted.bw
#bamCoverage -b $INPUT -o $OUTPUT


