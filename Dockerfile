FROM quay.io/ebigxa/atlas-db-scxa-base:0.1.0
# debian

ADD bin/* /usr/local/bin/
ADD postgres_routines /usr/local/postgres_routines
USER root
RUN chmod a+w /usr/local
# fixtures for tests need to be writable
RUN mkdir /tmp/fixtures
RUN chmod o+w /tmp/fixtures
USER micromamba
