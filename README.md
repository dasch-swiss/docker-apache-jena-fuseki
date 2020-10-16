# Docker Image for Apache Jena Fuseki

This repository hosts a Docker recipe for distributing Apache Jena Fuseki 2 server with SPARQL endpoint and web interface.

The Docker image is currently available from the Docker Hub as:

dasch-swiss/apache-jena-fuseki

Note that although these Docker images are based on the official Apache Jena Fuseki releases and do not alter them in any way, they do not constitute official releases from the Apache Software Foundation.

## Dockerfile overview
The Dockerfile uses the official openjdk:11-jre-slim-buster base image, which is based on the [debian](https://hub.docker.com/_/debian/):buster-slim image; this clocks in at about 69 MB.

The ENV variable FUSEKI_VERSION determines which version of Fuseki is downloaded. Updating the version also requires updating the FUSEKI_SHA512 variable, which values should match the official Jena download .tar.gz.sha512 hashes.

The ASF_MIRROR uses http://www.apache.org/dyn/mirrors/mirrors.cgi that redirect to a local mirror, with a fallback to the ASF_ARCHIVE http://archive.apache.org/dist/ for older versions. Note that due to subsequent sha512 checking these accessed with http rather than https.

To minimize layer size, there's a single RUN with curl, sha512sum, tar zxf and mv - thus the temporary files during download and extraction are not part of the final image.

Some files from the Apache Jena distributions are stripped, e.g., fuseki.war file.

The Fuseki image includes some helper scripts to do tdb loading using fuseki-server.jar. In addition Fuseki has a [docker-entrypoint.sh](https://github.com/dasch-swiss/docker-apache-jena-fuseki/blob/main/docker-entrypoint.sh) that populates shiro.ini with the password provided as -e ADMIN_PASSWORD to Docker, or with a new randomly generated password that is printed the first time.

## Releasing
Releasing should be done through the Github release process, which will kick-off a Github-CI job that will release the Docker Image under the release tag.
