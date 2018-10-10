#!/usr/bin/env Rscript
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
# readMM(gzfile(opt$matrix_path))->tpm_mtrx
gzfile(description = opt$matrix_path, open = 'r') -> matrix_con
file(description = opt$output_path, open = 'w') -> output_con

# Read rows (Genes), skipping index row. Is this safe? Is there always a gene name?
genes_i<-read.table(file=gzfile(opt$genes_path),
           header = FALSE,
           col.names = c("index","gene"),
           colClasses = c("NULL","character"))
# Read columns (Cell-id/run)
runs_j<-read.table(file=gzfile(opt$runs_path),
           header=FALSE,
           col.names = c("index","run"),
           colClasses = c("NULL","character"))
# Traverse tpm_mtrx object writing sequentially on an object that we write to disk, appending everynow and then.

# Skip first two lines (is this always the format?)
readLines(matrix_con, n = 2)->discard

line<-readLines(matrix_con, n = 1)
while ( length(line) > 0 ) {
    # Indexes: [1] Gene id, [2] Run id, [3] Expression value
    unlist(strsplit(trimws(line), split = " "))->indexes
    writeLines(con = output_con,
      text = paste(opt$exp_id, genes_i$gene[strtoi(indexes[1])], runs_j$run[strtoi(indexes[2])], indexes[3], sep=","))
    line<-readLines(matrix_con, n = 1)
}
close(matrix_con)
