FROM quay.io/ebigxa/atlas-db-scxa-base:0.1.2
# debian

ADD bin/* /usr/local/bin/
ADD postgres_routines /usr/local/postgres_routines
USER root
RUN chmod a+w /usr/local
USER micromamba
