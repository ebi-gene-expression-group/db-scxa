#!/usr/bin/env Rscript

library(optparse)
library(tidyr)
library(data.table)

option_list <- list( 
  make_option(c("-c", "--clusters-file"), dest="clusters_path"),
  make_option(c("-e", "--experiment-accession"), dest="exp_acc"),
  make_option(c("-o", "--output"), dest="output_path")
)

opt <- parse_args(OptionParser(option_list=option_list))

fread(opt$clusters_path, header = TRUE, check.names = FALSE, sep = '\t') -> clusters_wide
gather(clusters_wide, key = "cell_id", value = "cluster_id", -sel.K, -K) -> clusters_long

clusters_long$experiment_accession <- opt$exp_acc
names(clusters_long)[names(clusters_long) == 'K'] <- 'k'

fwrite(clusters_long[,c('experiment_accession','cell_id','k','cluster_id')],
          file=opt$output_path,
          row.names = FALSE,
          quote = TRUE)

