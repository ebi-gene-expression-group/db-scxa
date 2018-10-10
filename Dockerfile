FROM alpine:3.8

RUN apk update && apk add postgresql-client=10.5-r0 R=3.5.0-r1 bash
RUN apk update && apk add --virtual build-dependencies \
    build-base gcc wget R-dev && \
    R -e "install.packages(c('optparse','tidyr','Matrix'), repos='https://cloud.r-project.org/')" && \
    apk del build-dependencies

ADD bin/* /usr/local/bin/
ADD postgres_routines /usr/local/postgres_routines
