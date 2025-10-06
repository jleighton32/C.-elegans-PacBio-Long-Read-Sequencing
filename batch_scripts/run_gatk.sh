#!/bin/bash
#SBATCH --mem=50G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --time=10:00:00
#SBATCH --array=2-20%19
#SBATCH --output=slurm_%A_%a.out
#SBATCH -p uri-cpu,cpu

cd /work/pi_nhowlett_uri_edu/jessie/New-All-20-Bam/

module load samtools/1.19.2
module load picard/3.1.1
#module load snpeff/2017-11-24

GATK_JAR=/modules/spack/packages/linux-ubuntu24.04-x86_64_v3/gcc-13.2.0/gatk-4.5.0.0-233ue7wprbz2lqj4ngnykslyvzbawyvw/bin/gatk-package-4.5.0.0-local.jar

# get job array index value
AR=$(($SLURM_ARRAY_TASK_ID))

# get SAM file containing alignments to C. elegans genome performed with minimap2
SAM=$(find ~+ -name "*.sam" | sort -V | head -n $AR | tail -n 1)

# create output directory to store results
DIR=$(echo $SAM | rev | cut -f2- -d"/" | rev)
mkdir -p $DIR/gatk
PFX=$(echo $SAM | rev | cut -f2 -d"." | cut -f1 -d"/" | rev)
SAMPLE=$(echo $SAM | rev | cut -f2 -d"." | cut -f1 -d"/" | rev| cut -f1 -d"_")

# sort and convert sam file to bam file (using Picard is required instead of samtools to run gatk)
java -jar $PICARD SortSam INPUT=$SAM OUTPUT=$(echo $DIR)/gatk/$(echo $PFX)_sorted_picard.bam SORT_ORDER=coordinate

# mark duplicate reads by Picard
java -jar $PICARD MarkDuplicates INPUT=$(echo $DIR)/gatk/$(echo $PFX)_sorted_picard.bam OUTPUT=$(echo $DIR)/gatk/$(echo $PFX)_dup.bam METRICS_FILE=$(echo $DIR)/gatk/metrics.txt

# update sorted bam file by adding the @RG tag in the header section
samtools addreplacerg -r '@RG\tID:$SAMPLE\tSM:$SAMPLE' $(echo $DIR)/gatk/$(echo $PFX)_dup.bam -o $(echo $DIR)/gatk/$(echo $PFX)_dup_up.bam

# index the sorted bam file with duplicates marked
samtools index $(echo $DIR)/gatk/$(echo $PFX)_dup_up.bam

# perform variant calling with GATK
java -jar $GATK_JAR HaplotypeCaller -R /work/pi_nhowlett_uri_edu/Celegans_PacBio_CNV_2025/GCF_000002985.6_WBcel235_genomic.fna -I $(echo $DIR)/gatk/$(echo $PFX)_dup_up.bam -O $(echo $DIR)/gatk/$(echo $PFX)_raw_variants.vcf 

# extract SNPs
java -jar $GATK_JAR SelectVariants -R /work/pi_nhowlett_uri_edu/Celegans_PacBio_CNV_2025/GCF_000002985.6_WBcel235_genomic.fna -V $(echo $DIR)/gatk/$(echo $PFX)_raw_variants.vcf -select-type SNP -O $(echo $DIR)/gatk/$(echo $PFX)_raw_snps.vcf

# extract Indels
java -jar $GATK_JAR SelectVariants -R /work/pi_nhowlett_uri_edu/Celegans_PacBio_CNV_2025/GCF_000002985.6_WBcel235_genomic.fna -V $(echo $DIR)/gatk/$(echo $PFX)_raw_variants.vcf -select-type INDEL -O $(echo $DIR)/gatk/$(echo $PFX)_raw_indels.vcf

# filter SNPs
java -jar $GATK_JAR VariantFiltration -R /work/pi_nhowlett_uri_edu/Celegans_PacBio_CNV_2025/GCF_000002985.6_WBcel235_genomic.fna -V $(echo $DIR)/gatk/$(echo $PFX)_raw_snps.vcf -filter-name "QD_filter" -filter "QD<2.0" -filter-name "FS_filter" -filter "FS>60.0" -filter-name "MQ_filter" -filter "MQ<40.0" -filter-name "SOR_filter" -filter "SOR>10.0" -O $(echo $DIR)/gatk/$(echo $PFX)_filtered_snps.vcf

# filter Indels
java -jar $GATK_JAR VariantFiltration -R /work/pi_nhowlett_uri_edu/Celegans_PacBio_CNV_2025/GCF_000002985.6_WBcel235_genomic.fna -V $(echo $DIR)/gatk/$(echo $PFX)_raw_indels.vcf -filter-name "QD_filter" -filter "QD<2.0" -filter-name "FS_filter" -filter "FS>200.0" -filter-name "SOR_filter" -filter "SOR>10.0" -O $(echo $DIR)/gatk/$(echo $PFX)_filtered_indels.vcf

# count SNPs
java -jar $GATK_JAR CountVariants -V $(echo $DIR)/gatk/$(echo $PFX)_filtered_snps.vcf  -O $(echo $DIR)/gatk/$(echo $PFX)_filtered_snps_count.vcf

# count Indels 
java -jar $GATK_JAR CountVariants -V $(echo $DIR)/gatk/$(echo $PFX)_filtered_indels.vcf  -O $(echo $DIR)/gatk/$(echo $PFX)_filtered_indels_count.vcf



