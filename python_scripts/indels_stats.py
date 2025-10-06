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
    variant_size_threshold = int(sys.argv[3])
    output_dir = sys.argv[4]

    # create output summary files
    del_out = open(os.path.join(output_dir, f'{sample}_deletions_{variant_size_threshold}_info.tsv'), 'w')
    ins_out = open(os.path.join(output_dir, f'{sample}_insertions_{variant_size_threshold}_info.tsv'), 'w')
    
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
                    if v_size >= variant_size_threshold:
                        num_variants += 1
                        accession = GetGeneAccession(v, info_elements)
                        if 'unassigned_transcript_' in accession:
                            accession = 'NA'
                        if v_type == 'insertion':
                            ins_out.write(f'{sample}\t{count}\t{v}\t{ref}\t{v_size}\t{accession}\n')
                            insertions.append(v_size)
                        elif v_type == 'deletion':
                            del_out.write(f'{sample}\t{count}\t{v}\t{ref}\t{v_size}\t{accession}\n')  
                            deletions.append(v_size)
                if len(variants) > 1:
                    mul_variants += 1
    if insertions:
        print("Min insertion size:", min(insertions))
    else:
        print("NO insertions found.")
    if deletions:
        print("Min deletion size:", min(deletions))
    else:
        print("NO deletions found.")
    
    print(f'Number of multiple variants at a given location: {mul_variants}')

    # save variants size to files
    with open(os.path.join(output_dir, f'{sample}_deletions_{variant_size_threshold}_count.tsv'), 'w') as f:
        f.write('\n'.join([str(i) for i in deletions]))
    
    with open(os.path.join(output_dir, f'{sample}_insertions_{variant_size_threshold}_count.tsv'), 'w') as f:
        f.write('\n'.join([str(i) for i in insertions]))

    ## create boxplots
    #plt.figure(figsize=(8, 6))
    #ax = sns.boxplot(data=insert_df, x='sample', y='value')
    #ax.tick_params(axis='x', labelrotation=45)
    #plt.savefig('insertions_boxplots.png', dpi=300)

    #plt.figure(figsize=(8, 6))
    #ax = sns.boxplot(data=del_df, x='sample', y='value')
    #ax.tick_params(axis='x', labelrotation=45)
    #plt.savefig('deletions_boxplots.png', dpi=300)

