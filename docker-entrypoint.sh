#!/bin/bash
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

set -e

# Log with the same logging format as Fuseki
log() {
  printf "%s %-5s Entrypoint      :: %s\n" "$(date +%H:%M:%S)" "$1" "$2"
}
info() {
  log "INFO" "$1"
}
error() {
  log "ERROR" "$1" >&2
}

# copy shiro.ini
cp "$FUSEKI_HOME/shiro.ini" "$FUSEKI_BASE/shiro.ini"

# $ADMIN_PASSWORD can always override
if [ -n "$ADMIN_PASSWORD" ] ; then
  sed -i "s/^admin=.*/admin=$ADMIN_PASSWORD/" "$FUSEKI_BASE/shiro.ini"
fi

# Rebuild lucene index of the dataset specified
# by REBUILD_INDEX_OF_DATASET if set
if [ -n "$REBUILD_INDEX_OF_DATASET" ] ; then
  info "Rebuilding index of dataset ${REBUILD_INDEX_OF_DATASET}:"
  if java -cp /jena-fuseki/fuseki-server.jar jena.textindexer --desc="/fuseki/configuration/${REBUILD_INDEX_OF_DATASET}.ttl" ; then
    info "Successfully rebuilt index"
  else
    error "Failed rebuilding index"
    exit 1
  fi
fi

# Start Fueski server
exec "$@" &

# Wait until server is up
while [[ $(curl -I http://localhost:3030 2>/dev/null | head -n 1 | cut -d$' ' -f2) != '200' ]]; do
  sleep 1s
done

wait
