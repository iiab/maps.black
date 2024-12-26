#!/usr/bin/env bash
set -xeuo pipefail
. ../utils.sh

build() {
  set -xeuo pipefail
  if [ ! -f ./tilejson.squashfs ] || [ ! -z "$(find *.{sh,txt,json} -newer "./tilejson.squashfs")" ]; then
    rm -rf tilejson
    mkdir -p tilejson
    cp *.json tilejson/
    cp *.txt tilejson/
    for f in tilejson/*; do
      if [ ! -f "$f" ] || [[ $f == *".png" ]]; then
        continue
      fi
      if [[ $f == *".json" ]]; then
        jq -cr tostring "$f" | sponge "$f"
      fi
      gzip -9kf "$f"
      brotli -Zkf "$f"
    done
    find ./tilejson -type d -exec chmod 777 {} \;
    mksquashfs ./tilejson ./.tilejson.squashfs -exit-on-error -quiet -noD -comp zstd -Xcompression-level 6 -fstime 0 -all-time 0 -no-xattrs -all-root -no-progress -no-exports &&
      mv -f ./.tilejson.squashfs ./tilejson.squashfs
    rm -rf tilejson
  fi
}
