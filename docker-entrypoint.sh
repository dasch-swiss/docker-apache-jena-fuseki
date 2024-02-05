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
warn() {
  log "WARN" "$1" >&2
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

# Check if index rebuild marker file exists
if [ ! -n "$REBUILD_INDEX_OF_DATASET" ] && [ -f "$REBUILD_INDEX_MARKER_FILE" ] ; then
  info "Detected index rebuild marker file ${REBUILD_INDEX_MARKER_FILE}"
  REBUILD_INDEX_OF_DATASET="$(cat "$REBUILD_INDEX_MARKER_FILE" | sed "s/[^[:alpha:]_-]/_/g")"
  remove_marker_file=true
fi

# Rebuild lucene index of the dataset specified
# by REBUILD_INDEX_OF_DATASET if set
if [ -n "$REBUILD_INDEX_OF_DATASET" ] ; then
  index_base="${INDEX_BASE:-${FUSEKI_BASE}/lucene}"
  if [ -d "${index_base}/${REBUILD_INDEX_OF_DATASET}" ] ; then
    info "Deleting old index data of dataset ${REBUILD_INDEX_OF_DATASET}"
    if ! rm -r "${index_base}/${REBUILD_INDEX_OF_DATASET}" ; then
      error "Failed deleting old index data"
      exit 1
    fi
  fi
  info "Rebuilding index of dataset ${REBUILD_INDEX_OF_DATASET}..."
  if java -cp "${FUSEKI_HOME}/fuseki-server.jar" jena.textindexer --desc="${FUSEKI_BASE}/configuration/${REBUILD_INDEX_OF_DATASET}.ttl" ; then
    info "Successfully rebuilt index"
    # Remove marker on successful rebuild
    if [ "$remove_marker_file" = true ] && ! rm "$REBUILD_INDEX_MARKER_FILE" ; then
      warn "Failed removing index rebuild marker file ${REBUILD_INDEX_MARKER_FILE}"
    fi
  else
    error "Failed rebuilding index"
    exit 1
  fi
fi

# Start Fueski server
exec "$@"
