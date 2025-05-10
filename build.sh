#! /usr/bin/env bash
. ./utils.sh

build() {
  set -xeuo pipefail
  # Include rust in path in builder container
  export HOME="/root/"
  . "/root/.cargo/env"
  (cd apps/ && . ./build.sh && build)
  (cd tilejson/ && . ./build.sh && build)
  (cd client/ && . ./build.sh && build)
  (cd styles/ && . ./build.sh && build)
  (cd fonts/ && . ./build.sh && build)
  (cd resourcetiles/ && . ./build.sh && build)
  (cd naturalearth-raster/ && . ./build.sh && build)
  (cd naturalearth-vector/ && . ./build.sh && build)
  (cd osm-vector/ && . ./build.sh && build)
  (cd gh-pages/ && . ./build.sh && build_extracts)
  link_all
}

gh_pages() {
  set -xeuo pipefail
  (cd gh-pages/ && . ./build.sh && build)
}

prep() {
  rsync --update -avHP /usr/local/0-9se/sites/.maps.black/ /usr/local/0-9se/sites/maps.black/
}

for var in "$@"; do
  "$var"
done
