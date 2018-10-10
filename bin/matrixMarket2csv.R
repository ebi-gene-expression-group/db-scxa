#!/usr/bin/env Rscript

library(Matrix)
library(optparse)

option_list <- list(
  make_option(c("-m", "--matrix-file"), dest="matrix_path"),
  make_option(c("-r", "--rows-genes-file"), dest="genes_path"),
  make_option(c("-c", "--cols-runs-file"), dest="runs_path"),
  make_option(c("-e", "--experiment-id"), dest="exp_id"),
  make_option(c("-s", "--genes-step-size"), dest="genes_step", type="integer"),
  make_option(c("-o", "--output"), dest="output_path")
)

opt <- parse_args(OptionParser(option_list=option_list))
# This script will generate a tsv file for loading into postgres with the
# following columns: experiment_accession, gene_id, cell_id, expression_level

# Read data of the matrix
tpm_mtrx <- readMM(gzfile(opt$matrix_path))

# Read rows (Genes), skipping index row. Is this safe? Is there always a gene name?
genes_i <- read.table(file = gzfile(opt$genes_path),
                      header = FALSE,
                      col.names = c("index", "gene"),
                      colClasses = c("NULL", "character"))

# Read columns (Cell-id/run)
runs_j <- read.table(file = gzfile(opt$runs_path),
                     header =   FALSE,
                     col.names = c("index","run"),
                     colClasses = c("NULL","character"))

# Traverse tpm_mtrx object writing sequentially on an object that we write to disk, appending every now and then.
genes_per_it <- opt$genes_step
genes_steps <- seq(1, nrow(genes_i), genes_per_it)
num_genes <- nrow(genes_i)

for(g_i in genes_steps) {
  for(r_j in 1:nrow(runs_j)) {
    up_to <- min(g_i + genes_per_it - 1, num_genes)

    chunk <- data.frame(exp_acc = opt$exp_id,
                        gene_id = genes_i$gene[g_i:up_to],
                        cell_id = runs_j$run[r_j],
                        expression = tpm_mtrx[g_i:up_to, r_j])

    filtered_chunk <- subset(chunk, expression >0)

    if (nrow(filtered_chunk) > 0) {
      write.table(subset(chunk, expression > 0),
                  row.names = FALSE,
                  col.names = FALSE,
                  file = opt$output_path,
                  sep = ",",
                  append = TRUE,
                  quote = FALSE)
    }
  }
}
