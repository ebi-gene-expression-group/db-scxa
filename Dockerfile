FROM mambaorg/micromamba:0.17.0
# debian

RUN micromamba config --add channels defaults && \
    micromamba config --add channels conda-forge && \
    micromamba config --add channels bioconda && \
    micromamba install r-base r-tidyr r-optparse r-matrix openjdk r-data.table

USER root
# RUN apk update && apk add postgresql-client bash wget nodejs bats
RUN apt-get update && apt-get install -y postgresql-client wget nodejs bats
RUN wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/6.3.2/flyway-commandline-6.3.2-linux-x64.tar.gz | tar xvz && ln -s `pwd`/flyway-6.3.2/flyway /usr/local/bin

ADD bin/* /usr/local/bin/
ADD postgres_routines /usr/local/postgres_routines

ENV PATH "/bin:/sbin:/usr/bin:/usr/local/bin:/opt/conda/bin"
