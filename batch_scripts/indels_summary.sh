#!/bin/bash
#SBATCH --partition=uri-cpu,cpu
#SBATCH -c 20
#SBATCH --mem=10G
#SBATCH --output=/work/pi_nhowlett_uri_edu/jessie/bscripts/run/slurm_%J.out

cd /work/pi_nhowlett_uri_edu/jessie/New-All-20-Bam/

module load parallel/20240822
module load conda/latest
conda activate /work/pi_nhowlett_uri_edu/jessie/conda-envs/variant-calling-env

# retrieve accession id of variants with size >= variant_size_thd
variant_size_thd=1000
output_dir=/work/pi_nhowlett_uri_edu/jessie/New-All-20-Bam/gatk_results_stats/variant_size_thd_$variant_size_thd
mkdir -p $output_dir
cat indels_vcf_ann | parallel --colsep '\t' -j $SLURM_CPUS_ON_NODE python /work/pi_nhowlett_uri_edu/jessie/pscripts/indels_stats.py {2} {1} $variant_size_thd $output_dir

# retrieve description of genes with ncbi datasets
ncbi_datasets_exec='/work/pi_nhowlett_uri_edu/jessie/tools/datasets'
ncbi_dataformat_exec='/work/pi_nhowlett_uri_edu/jessie/tools/dataformat'
variants_type=("insertions" "deletions")
for variant in "${variants_type[@]}"; do
        echo $variant
        while read LINE; do
                sample=$(echo $LINE | cut -f1 -d" ")
                awk '{print $NF}' $output_dir/$(echo $sample)_$(echo $variant)_$(echo $variant_size_thd)_info.tsv > sample_accessions
                ncbi_datasets_input=""
                while read ACCESSION; do
                        if [[ $ACCESSION != 'NA' ]]; then
                                ncbi_datasets_input+=",$ACCESSION"
                        fi
                done < sample_accessions
		if [ -n "$ncbi_datasets_input" ]; then
			echo -e "$sample\tthere are $variant with size >= $variant_size_thd"
                	$ncbi_datasets_exec summary gene accession $ncbi_datasets_input --as-json-lines | $ncbi_dataformat_exec  tsv gene --template summary > $output_dir/$(echo $sample)_$(echo $variant)_$(echo $variant_size_thd)_variants_description.tsv
		else
			echo -e "$sample\tthere are no $variant with size >= $variant_size_thd"
		fi
        done < indels_vcf_ann
done
rm sample_accessions

