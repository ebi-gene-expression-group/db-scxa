#!/usr/bin/env python

import argparse
import pandas as pd
import csv

# Parse command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument("-c", "--clusters-file", dest="clusters_path", help="Path to clusters file")
parser.add_argument("-e", "--experiment-accession", dest="exp_acc", help="Experiment accession")
parser.add_argument("-o", "--output", dest="output_path", help="Output file path")
args = parser.parse_args()

# Read clusters file
clusters_wide = pd.read_csv(args.clusters_path, sep='\t', header=0, usecols=lambda x: x != "sel.K")

# Reshape data from wide to long format
clusters_long = pd.melt(clusters_wide, id_vars=['K'], var_name='cell_id', value_name='cluster_id')

# Add experiment accession column
clusters_long['experiment_accession'] = args.exp_acc

# Rename 'K' column to 'k'
clusters_long.rename(columns={'K': 'k'}, inplace=True)

# Select and reorder columns
columns = ['experiment_accession', 'cell_id', 'k', 'cluster_id']

# Write output to file
clusters_long.to_csv(args.output_path, index=False, columns=columns, quoting=csv.QUOTE_NONNUMERIC)
