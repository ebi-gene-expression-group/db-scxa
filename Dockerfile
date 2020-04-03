FROM continuumio/miniconda3:4.8.2
# debian

RUN /opt/conda/bin/conda config --add channels defaults && \
    /opt/conda/bin/conda config --add channels conda-forge && \
    /opt/conda/bin/conda config --add channels bioconda && \
    /opt/conda/bin/conda install r-base r-tidyr r-optparse r-matrix openjdk

USER root
# RUN apk update && apk add postgresql-client bash wget nodejs bats
RUN apt-get install -y postgresql-client wget nodejs bats
RUN wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/6.3.2/flyway-commandline-6.3.2-linux-x64.tar.gz | tar xvz && ln -s `pwd`/flyway-6.3.2/flyway /usr/local/bin

ADD bin/* /usr/local/bin/
ADD postgres_routines /usr/local/postgres_routines

ENV PATH "/bin:/sbin:/usr/bin:/usr/local/bin:/opt/conda/bin"
