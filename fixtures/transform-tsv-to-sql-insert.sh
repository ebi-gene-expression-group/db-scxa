# Transform TSV files to SQL INSERTs
sed -En "s/(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_analytics(experiment_accession, gene_id, cell_id, expression_level) VALUES ('\1', '\2', '\3', \4);/p" scxa_analytics.tsv >> scxa_analytics.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_dimension_reduction(id, experiment_accession, method, parameterisation, priority) VALUES (\1, '\2', '\3', '\4', \5);/p" scxa_dimension_reduction.tsv >> scxa_dimension_reduction.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_coords(cell_id, x, y, dimension_reduction_id) VALUES ('\1', \2, \3, \4);/p" scxa_coords.tsv >> scxa_coords.sql

sed -En "s/(.+)\t(.+)\t(.+)/INSERT INTO scxa_cell_group_membership(experiment_accession, cell_id, cell_group_id) VALUES ('\1', '\2', \3);/p" scxa_cell_group_membership.tsv >> scxa_cell_group_membership.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_cell_group_marker_genes(id, gene_id, cell_group_id, marker_probability) VALUES (\1, '\2', \3, \4);/p" scxa_cell_group_marker_genes.tsv >> scxa_cell_group_marker_genes.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_cell_group_marker_gene_stats(gene_id, cell_group_id, marker_id, expression_type, mean_expression, median_expression) VALUES ('\1', \2, \3, \4, \5, \6);/p" scxa_cell_group_marker_gene_stats.tsv >> scxa_cell_group_marker_gene_stats.sql

sed -En "s/(.+)\t(.+)\t(.+)\t(.+)/INSERT INTO scxa_cell_group(id, experiment_accession, variable, value) VALUES (\1, '\2', '\3', '\4');/p" scxa_cell_group.tsv >> scxa_cell_group.sql