FROM quay.io/ebigxa/atlas-db-scxa-base:0.1.0
# debian

ADD bin/* /usr/local/bin/
ADD postgres_routines /usr/local/postgres_routines

ENV PATH "/bin:/sbin:/usr/bin:/usr/local/bin:/opt/conda/bin"
