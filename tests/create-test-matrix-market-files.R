#!/usr/bin/env Rscript

library(Matrix)

# From irap
write.tsv <- function(x,file,header=TRUE,rownames.label=NULL,fix=TRUE,gzip=FALSE) {
  ##
  if (!is.null(x)) {
    if (!is.matrix(x)) {
      x <- as.matrix(x)
    }
    if (fix) {
      x <- apply(x,c(1,2),gsub,pattern="'",replacement="")
    }
    if ( !is.null(rownames.label) ) {
      y <- cbind(rownames(x),x)
      colnames(y) <- append(rownames.label,colnames(x))
      x <- y
    }
  }
  if ( gzip ) {
    con=gzfile(file,"w+")
  } else {
    con=file(file,"w+")
  }
  write.table(x,con,sep="\t",row.names=F,col.names=header,quote=F)
  tryCatch(close(con),error=function(x) return(NULL))
  invisible(1)
}

args = commandArgs(trailingOnly=TRUE)
exp_id <- args[1]
# Creates a random sparse matrix and writes it to matrix market, for testing
# purposes.
genes_i <- sort(sample.int(1000,300)); # 300 genes out of 1000 will have some expression
runs_j <- sort(sample.int(100,300, replace=TRUE)); # Showing up in 300 runs out of 100 

exp <- round(sample(100,300, replace = TRUE)/20,digits = 2) # 300 values of expression
exp_matrix <- sparseMatrix(genes_i, runs_j, x=exp,dims = c(1000,100))
rownames(exp_matrix) <- paste(rep("GENE",1000),1:1000,sep = "") # 1000 genes
colnames(exp_matrix) <- paste(rep("SRR",100),1:100,sep="") # 100 runs

writeMM(exp_matrix,file=paste(exp_id,".expression_tpm.mtx",sep=""))
system(paste0("gzip -f ",paste(exp_id,".expression_tpm.mtx",sep="")))
write.tsv(data.frame(list(ids=seq(1,nrow(exp_matrix)),lab=rownames(exp_matrix))),
          header=FALSE,rownames.label=NULL,fix=FALSE,gzip=TRUE,file=paste(exp_id,".expression_tpm.mtx_rows.gz",sep=""))

write.tsv(data.frame(list(ids=seq(1,ncol(exp_matrix)),lab=colnames(exp_matrix))),
          header=FALSE,rownames.label=NULL,fix=FALSE,gzip=TRUE,file=paste(exp_id,".expression_tpm.mtx_cols.gz",sep=""))

# Write query result file to compare against.
whereClause<-paste(sprintf("(gene_id = '%s' AND cell_id = '%s' AND experiment_accession = '%s')",
                           rownames(exp_matrix)[genes_i],
                           colnames(exp_matrix)[runs_j], 
                           rep(exp_id,length(genes_i))),
                   collapse = " OR ")
query<-paste("SELECT experiment_accession, gene_id, cell_id, expression_level FROM scxa_analytics WHERE ",
             whereClause, " ORDER BY gene_id, cell_id", ";", sep="")

fileConn<-file(paste(exp_id,".query_test.sql",sep=""))
writeLines(query, fileConn)
close(fileConn)

query_result<-data.frame(experiment_accession=rep(exp_id,300),
                        gene_id=rownames(exp_matrix)[genes_i],
                        cell_id=colnames(exp_matrix)[runs_j],
                        expression_level=exp)
attach(query_result)
write.table(query_result[order(gene_id, cell_id),], file=paste(exp_id,".query_expected.txt",sep=""), quote = FALSE, row.names = FALSE)



