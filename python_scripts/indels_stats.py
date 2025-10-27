import os
import statistics
import sys
from collections import defaultdict
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt


def GetGeneAccession(variant, info_elements):
    accession = 'NA'
    # get gene(s) associated with variant
    for e in info_elements:
        if e.split('=')[0] == 'ANN':
            annotations = e.split(',')
            annotations[0] = annotations[0][4:]
            for a in annotations:
                # get variant
                ann_v = a.split('|')[0]
                if ann_v == variant:
                    if a.split('|')[5] in ['transcript', 'protein_coding']:
                        accession = a.split('|')[6]
    return accession


if __name__ == "__main__":
    vcf_file = sys.argv[1]
    sample = sys.argv[2]
    output_dir = sys.argv[3]

    # create a single output summary file
    summary_out = open(os.path.join(output_dir, f'{sample}_variants_info.tsv'), 'w')
    summary_out.write("Sample\tVariant\tReference\tSize\tAccession\tType\n")
    
    # store size of insertions and deletions
    insertions = []
    deletions = []
    # store the number of multiple variants
    mul_variants = 0
    # store the number of variants
    num_variants = 0
    with open(vcf_file, 'r') as f:
        for count, line in enumerate(f, 1):
            # ignore header (lines that start with #)
            if line.rstrip()[0] != '#':
                # get reference and variant
                ref = line.rstrip().split('\t')[3]
                variant = line.rstrip().split('\t')[4]
                info_elements = line.rstrip().split('\t')[7].split(';')
                # multiple variants are provided as a list separated by commas
                variants = variant.split(',')
                for v in variants:
                    v_size = int()
                    v_type = ''
                    # identify if variant is an insertion or a deletion
                    if len(ref) > len(v):
                        v_size = len(ref) - len(v)
                        v_type = 'deletion'
                    if len(v) > len(ref):
                        v_size = len(v) - len(ref)
                        v_type = 'insertion'




                    if v_type:
                        num_variants += 1
                        accession = GetGeneAccession(v, info_elements)
                        if 'unassigned_transcript_' in accession:
                            accession = 'NA'
     # Write variant info to summary file
    summary_out.write(f"{sample}\t{v}\t{ref}\t{v_size}\t{accession}\t{v_type}\n")    
                if len(variants) > 1:
                    mul_variants += 1
    # print basic stats
    print(f"Total variants: {num_variants}")
    print(f"Multiple variant positions: {mul_variants}")

    if insertions:
        print(f"Insertions: {len(insertions)} (min={min(insertions)}, max={max(insertions)})")
    else:
        print("No insertions found.")

    if deletions:
        print(f"Deletions: {len(deletions)} (min={min(deletions)}, max={max(deletions)})")
    else:
        print("No deletions found.")


    ## create boxplots
    #plt.figure(figsize=(8, 6))
    #ax = sns.boxplot(data=insert_df, x='sample', y='value')
    #ax.tick_params(axis='x', labelrotation=45)
    #plt.savefig('insertions_boxplots.png', dpi=300)

    #plt.figure(figsize=(8, 6))
    #ax = sns.boxplot(data=del_df, x='sample', y='value')
    #ax.tick_params(axis='x', labelrotation=45)
    #plt.savefig('deletions_boxplots.png', dpi=300)

