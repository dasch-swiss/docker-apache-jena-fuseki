#   Licensed to the Apache Software Foundation (ASF) under one or more
#   contributor license agreements.  See the NOTICE file distributed with
#   this work for additional information regarding copyright ownership.
#   The ASF licenses this file to You under the Apache License, Version 2.0
#   (the "License"); you may not use this file except in compliance with
#   the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Credits: Mainly copied from https://github.com/stain/jena-docker

FROM eclipse-temurin:21-jre-jammy

ENV LANG C.UTF-8
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
       tini bash curl ca-certificates findutils coreutils pwgen procps \
    ; \
    rm -rf /var/lib/apt/lists/*


# Update below according to https://jena.apache.org/download/
# and checksum for apache-jena-fuseki-4.x.x.tar.gz.sha512
ENV FUSEKI_SHA512 c7b9fa452cdec19c50ee08ee191012b26c7b51f1ee5c5143db3047e0545c007599fbc08481fa61df5aef766a796e43262c209fc42578f2e532c0ab0c19dcbc51
ENV FUSEKI_VERSION 5.0.0
# No need for https due to sha512 checksums below
ENV ASF_MIRROR http://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=
ENV ASF_ARCHIVE http://archive.apache.org/dist/

LABEL org.opencontainers.image.url https://github.com/stain/jena-docker/tree/master/jena-fuseki
LABEL org.opencontainers.image.source https://github.com/stain/jena-docker/
LABEL org.opencontainers.image.documentation https://jena.apache.org/documentation/fuseki2/
LABEL org.opencontainers.image.title "Apache Jena Fuseki"
LABEL org.opencontainers.image.description "Fuseki is a SPARQL 1.1 server with a web interface, backed by the Apache Jena TDB RDF triple store."
LABEL org.opencontainers.image.version ${FUSEKI_VERSION}
LABEL org.opencontainers.image.licenses "(Apache-2.0 AND (GPL-2.0 WITH Classpath-exception-2.0) AND GPL-3.0)"
LABEL org.opencontainers.image.authors "Apache Jena Fuseki by https://jena.apache.org/; this image by https://orcid.org/0000-0001-9842-9718"

# Config and data
VOLUME /fuseki
ENV FUSEKI_BASE /fuseki
ENV INDEX_BASE $FUSEKI_BASE/lucene


# Installation folder
ENV FUSEKI_HOME /jena-fuseki

WORKDIR /tmp
# published sha512 checksum
RUN echo "$FUSEKI_SHA512  fuseki.tar.gz" > fuseki.tar.gz.sha512
# Download/check/unpack/move in one go (to reduce image size)
RUN  (curl --location --silent --show-error --fail --retry-connrefused --retry 3 --output fuseki.tar.gz ${ASF_MIRROR}jena/binaries/apache-jena-fuseki-$FUSEKI_VERSION.tar.gz || \
      curl --fail --silent --show-error --retry-connrefused --retry 3 --output fuseki.tar.gz $ASF_ARCHIVE/jena/binaries/apache-jena-fuseki-$FUSEKI_VERSION.tar.gz) && \
      sha512sum -c fuseki.tar.gz.sha512 && \
      tar zxf fuseki.tar.gz && \
      mv apache-jena-fuseki* $FUSEKI_HOME && \
      rm fuseki.tar.gz* && \
      cd $FUSEKI_HOME && rm -rf fuseki.war && chmod 755 fuseki-server

# Verify that the binary works
RUN  bash -c '[ "$($FUSEKI_HOME/fuseki-server --version)" == "Apache Jena Fuseki version $FUSEKI_VERSION" ]'

# shiro.ini contains a default password. To override, start
# container with ADMIN_PASSWORD environment variable set
COPY shiro.ini $FUSEKI_HOME/shiro.ini
COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh

# Periodically check whether Fuseki is running and
# responding to a ping or whether text indexer is
# running
HEALTHCHECK --interval=15s --timeout=3s --retries=3 --start-period=30s \
  CMD curl -sS --fail 'http://localhost:3030/$/ping' || \
      pgrep -f "jena.textindexer" >/dev/null || \
      exit 1

# Where we start our server from
WORKDIR $FUSEKI_HOME
EXPOSE 3030
ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]
CMD ["/jena-fuseki/fuseki-server"]
