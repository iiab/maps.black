#!/usr/bin/env bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

export appdir="$SCRIPT_DIR/apps"

export PATH="$appdir:$appdir/java_upstream/bin:$PATH"
export JAVA_HOME="$appdir/java_upstream/"

export pmtilesVersion="1.27.2"
export tippecanoeVersion="2.77.0"
export planetilerVersion="0.8.4"
export martinVersion="0.16.0"
export lakelinesVersion="12"
export spreetVersion="0.11.0"
export maputnikVersion="2.1.1"
export styleSpecVersion="22.0.1"

export protomapsVersion="e04e3f5e67ea5b7789716dfeb3e16a948355c05c"
export mbutilVersion="544c76eea925e3c1bc129f601e314ea9701bfc79"
export fontMakerVersion="9ea6884143a2683d2c5563f820fe331fe6773742"

export googleFontsVersion="9c93ba3639f2d4bff91f5e7c0ede6e40e92fca79"

export nunitoFontVersion="ad92819e6638e5b7b321c32e0d7b6d64cf5b4a94"
export nunitoSansFontVersion="058bd7a2f33d6ad5ef1df985b3db403622016a8c"
export metropolisFontVersion="85fa62524e9eb40047bbf64830022e59a02cbaed"
export openSansFontVersion="bd7e37632246368c60fdcbd374dbf9bad11969b6"
export robotoFontVersion="38062f4b4a0be4346d07a928408da21602545e9e"
export robotoSlabFontVersion="67af3ce9c4ca574419e1295b6165a2eeee112e6e"
export josefinSansFontVersion="132fdfd997a62411375d15e20ef81285923750c6"
export jostFontVersion="35f141c970538f1ed0f235789c19156b3ce2a762"
export montserratFontVersion="cc8daf2e7085006b9c112542fc82b58afc13521d"
export poppinsFontVersion="be5b80d711415eccf6b65aad15bced8bbb6a67a2"

export IMAGE_BASE_VERSION="bookworm" # Debian 12

# $1 repo
# $2 version
# $3 pattern
# $4 prefix
check_tag() {
  LATEST=$(git ls-remote --tags --refs "$1" "$3" | grep -oE '[^/]*$' | sed '/-/!{s/$/_/}' | sort -rV | sed 's/_$//' | grep -Ev '(dev|rc|alpha|beta|test)' | head -n1)
  if [[ "$4$2" != "$LATEST" ]]; then
    echo "Outdated $1. Requested: $4$2, Latest: $LATEST"
  fi
}

# $1 repo
# $2 commit
check_commit() {
  LATEST=$(git ls-remote "$1" | grep -oE '^\w*' | head -n1)
  if [[ "$2" != "$LATEST" ]]; then
    echo "Outdated $1. Requested: $2, Latest: $LATEST"
  fi
}

check_versions() {
  check_tag https://github.com/protomaps/go-pmtiles.git $pmtilesVersion 'v*' "v"
  check_tag https://github.com/felt/tippecanoe.git $tippecanoeVersion '*' ""
  check_tag https://github.com/onthegomap/planetiler.git $planetilerVersion 'v*' "v"
  check_tag https://github.com/maplibre/martin.git $martinVersion 'v*' "v"
  check_tag https://github.com/acalcutt/osm-lakelines $lakelinesVersion 'v*' "v"
  check_tag https://github.com/flother/spreet.git $spreetVersion 'v*' "v"
  check_tag https://github.com/maplibre/maputnik.git $maputnikVersion 'v*' "v"

  check_commit https://github.com/maps-black/basemaps.git $protomapsVersion
  check_commit https://github.com/maplibre/font-maker.git $fontMakerVersion
  check_commit https://github.com/mapbox/mbutil.git $mbutilVersion

  check_commit https://github.com/google/fonts.git $googleFontsVersion

  check_commit https://github.com/vernnobile/NunitoFont.git $nunitoFontVersion
  check_commit https://github.com/googlefonts/NunitoSans.git $nunitoSansFontVersion
  check_commit https://github.com/dw5/Metropolis.git $metropolisFontVersion
  check_commit https://github.com/googlefonts/opensans.git $openSansFontVersion
  check_commit https://github.com/googlefonts/roboto-2.git $robotoFontVersion
  check_commit https://github.com/googlefonts/robotoslab.git $robotoSlabFontVersion
  check_commit https://github.com/googlefonts/josefinsans.git $josefinSansFontVersion
  check_commit https://github.com/indestructible-type/Jost.git $jostFontVersion
  check_commit https://github.com/JulietaUla/Montserrat.git $montserratFontVersion
  check_commit https://github.com/itfoundry/Poppins.git $poppinsFontVersion
}
export -f check_versions

systemd_units() {
  set -xeuo pipefail
  publicDir="$SCRIPT_DIR/public"
  systemdDir="$SCRIPT_DIR/systemd"
  systemdPublicDirName="$(systemd-escape "${publicDir#/}")"
  for f in $publicDir/*.squashfs; do
    filename="${f##*/}"
    dirpath="$(dirname "$f")"
    packageName="${filename/.squashfs/}"
    systemdPackageName="$(systemd-escape "$packageName")"
    if [[ $packageName == *"terrarium"* ]]; then
      continue
    fi
    if [ -f $systemdDir/$systemdPublicDirName-${systemdPackageName}.automount ]; then
      continue
    fi
    cat >$systemdDir/$systemdPublicDirName-${systemdPackageName}.mount <<EOF
[Mount]
Where=$publicDir/${packageName}
What=$publicDir/${packageName}.squashfs
Type=squashfs
[Install]
WantedBy=multi-user.target
EOF

    cat >$systemdDir/$systemdPublicDirName-${systemdPackageName}.automount <<EOF
[Automount]
Where=$publicDir/${packageName}
[Install]
WantedBy=multi-user.target
EOF

    cat >$systemdDir/$systemdPublicDirName-${systemdPackageName}.squashfs.path <<EOF
[Path]
PathChanged=$publicDir/${packageName}.squashfs
[Install]
WantedBy=multi-user.target
EOF
    # Double-escape name for usage in systemdunit
    combinedName="$systemdPublicDirName-${systemdPackageName}.mount"
    restartName="${combinedName//\\/\\\\}"
    cat >$systemdDir/$systemdPublicDirName-${systemdPackageName}.squashfs.service <<EOF
[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl try-restart $restartName
[Install]
WantedBy=multi-user.target
EOF
    systemctl link --now \
      $systemdDir/$systemdPublicDirName-${systemdPackageName}.mount \
      $systemdDir/$systemdPublicDirName-${systemdPackageName}.automount \
      $systemdDir/$systemdPublicDirName-${systemdPackageName}.squashfs.path \
      $systemdDir/$systemdPublicDirName-${systemdPackageName}.squashfs.service
    systemctl enable --now \
      $systemdPublicDirName-${systemdPackageName}.automount \
      $systemdPublicDirName-${systemdPackageName}.squashfs.path
  done

  # We handle terrarium differently since they do an overlay mount. Ideally we'd still automount them, but the combination of overlayfs and autofs (what is used to automount) is not supported by linux.
  for mountName in "terrarium-z0-z10" "terrarium-z11" "terrarium-z12" "terrarium-z13"; do
    packageName="$(systemd-escape "$mountName")"
    if [ -f $systemdDir/$systemdPublicDirName-${packageName}.mount ]; then
      continue
    fi
    if [ -f $publicDir/${mountName}.squashfs ]; then
      cat >$systemdDir/$systemdPublicDirName-${packageName}.mount <<EOF
[Mount]
Where=$publicDir/${mountName}
What=$publicDir/${mountName}.squashfs
Type=squashfs
[Install]
WantedBy=multi-user.target
EOF
      systemctl link --now $systemdDir/$systemdPublicDirName-${packageName}.mount
      systemctl enable --now $systemdPublicDirName-${packageName}.mount
    fi
  done
  if [ ! -f $systemdDir/$systemdPublicDirName-terrarium.mount ]; then
    cat >$systemdDir/$systemdPublicDirName-terrarium.mount <<EOF
[Mount]
What=overlay
Where=$publicDir/terrarium
Type=overlay
Options=auto,lowerdir=$publicDir/terrarium-z0-z10:$publicDir/terrarium-z11:$publicDir/terrarium-z12:$publicDir/terrarium-z13
[Install]
WantedBy=multi-user.target
EOF
    systemctl link --now $systemdDir/$systemdPublicDirName-terrarium.mount
    systemctl enable --now $systemdPublicDirName-terrarium.mount
  fi
}
export -f systemd_units

unmount_unlink_all() {
  set -xeuo pipefail
  systemdDir="$SCRIPT_DIR/systemd"
  for f in $systemdDir/*; do
    if [ ! -f "$f" ]; then
      continue
    fi
    filename="${f##*/}"
    systemctl is-active ${filename} && systemctl stop ${filename} || true
    systemctl list-unit-files ${filename} >/dev/null && systemctl disable ${filename}
  done
  rm -rf $SCRIPT_DIR/public/* $SCRIPT_DIR/systemd/*
}
export -f unmount_unlink_all

link_all() {
  (
    set -xeuo pipefail
    cd "$SCRIPT_DIR"
    # Create symlinks to all the archives created
    for f in ./*/*.{mbtiles,pmtiles,squashfs}; do
      if [ ! -f "$f" ]; then
        continue
      fi
      filename="${f##*/}"
      _dirpath="$(dirname "$f")"
      dirpath="${_dirpath##*/}"
      if [[ $filename == *"prep"* ]]; then
        continue
      fi
      if [ "$dirpath" == "public" ]; then
        continue
      fi
      # Create link if it does not exist
      if [ ! -f "./public/$filename" ]; then
        ln -sf "../$dirpath/$filename" "./public/$filename"
      fi
      # Check if the link is older, if so touch it to make systemd remount
      if [[ "./$dirpath/$filename" -nt "./public/$filename" ]]; then
        touch --no-dereference --reference "./$dirpath/$filename" "./public/$filename"
      fi
    done
  )
}
export -f link_all

download_with_check() {
  set -xeuo pipefail
  for url in "$@"; do
    filename="${url##*/}"
    if curl --remote-time --fail --silent --time-cond "$filename" -L -o "./.$filename" "$url"; then
      [ -f "./.$filename" ] && mv -f "./.$filename" "$filename" || true
    else
      echo "failed downloading $url"
    fi
  done
}
export -f download_with_check

workdisk_prep() {
  if [ ! -d "$SCRIPT_DIR/workdisk" ]; then
    mkdir -p "$SCRIPT_DIR/workdisk"
  fi
  if [ ! -f "$SCRIPT_DIR/workdisk.img" ]; then
    truncate -s 400G "$SCRIPT_DIR/workdisk.img"
    mkfs.btrfs -f -m single "$SCRIPT_DIR/workdisk.img"
    # Ideally we'd use a new throwaway disk, but for some reason mkfs.btrfs failes with "ERROR: $DISKNAME.img is mounted" even when it clearly isn't when running in the unit
    # mount -t btrfs -o noacl,nobarrier,noatime,nodatasum,max_inline=4096 "$SCRIPT_DIR/workdisk.img" "$SCRIPT_DIR/workdisk"
  fi

  systemdDir="$SCRIPT_DIR/systemd"
  escapedPath="$(systemd-escape "${SCRIPT_DIR#/}")"
  cat >$systemdDir/$escapedPath-workdisk.mount <<EOF
[Mount]
Where=$SCRIPT_DIR/workdisk
What=$SCRIPT_DIR/workdisk.img
Type=btrfs
Options=noacl,nobarrier,noatime,nodatasum,max_inline=4096
[Install]
WantedBy=multi-user.target
EOF
  systemctl link --now $systemdDir/$escapedPath-workdisk.mount
  systemctl enable --now $escapedPath-workdisk.mount
}
export -f workdisk_prep

mbtiles_to_squashfs() {
  set -xeuo pipefail
  if [ ! -d "$SCRIPT_DIR/workdisk" ]; then
    echo "No workdisk found, run workdisk_prep"
    exit 1
  fi
  input="$1"
  output="$2"
  format="$3"
  find "$SCRIPT_DIR/workdisk/tiles/" -delete || true
  # mksquashfs flags based on https://github.com/plougher/squashfs-tools/issues/238 and 128GB RAM
  # Changed from the issue: -mem 8GB->8G
  # -processors 16 to not gobble up all the available CPU
  mb-util --silent "$input" "$SCRIPT_DIR/workdisk/tiles" --image_format="$format" &&
    mksquashfs $SCRIPT_DIR/workdisk/tiles $output -exit-on-error -quiet -noD -comp zstd -Xcompression-level 6 -fstime 0 -all-time 0 -no-xattrs -all-root -no-progress -no-exports -mem 8G -processors 16
  find "$SCRIPT_DIR/workdisk/tiles/" -delete
  mkdir -p test-squash
  if ! mount $output test-squash; then
    echo 'failed to mount resulting squashfs'
    rm -f $output test-squash
  fi
  umount ./test-squash
  rm -rf test-squash
}
export -f mbtiles_to_squashfs

mbtiles_to_erofs() {
  set -xeuo pipefail
  input="$1"
  output="$2"
  format="$3"
  uniqdiskname="tmpdisk$(uuidgen)"
  umount ./${uniqdiskname} || true
  rm -rf ${uniqdiskname}.img ${uniqdiskname} test-squash
  truncate -s 400G ${uniqdiskname}.img
  mkfs.btrfs -m single ${uniqdiskname}.img
  mkdir -p ${uniqdiskname}
  mount -t btrfs -o noacl,nobarrier,noatime,nodatasum,max_inline=4096 ./${uniqdiskname}.img ./${uniqdiskname}
  mb-util --silent "$input" ./${uniqdiskname}/tiles --image_format="$format" &&
    mkfs.erofs $output ./${uniqdiskname}/tiles -E fragments,dedupe,ztailpacking,force-inode-compact --all-root -T0 --force-uid=0 --force-gid=0 -x -1 -zlz4
  umount ./${uniqdiskname}
  mkdir -p test-erofs
  if ! mount $output test-erofs; then
    echo 'failed to mount resulting erofs'
    rm -f $output ${uniqdiskname}.img ${uniqdiskname} test-erofs
  fi
  umount ./test-erofs
  rm -rf ${uniqdiskname}.img ${uniqdiskname} test-erofs
}
export -f mbtiles_to_erofs

build_image() {
  set -xeuo pipefail
  umount /tmp/maps.black/proc || true
  rm -rf /tmp/maps.black/
  debootstrap --variant=minbase "${IMAGE_BASE_VERSION}" /tmp/maps.black/

  mount --bind /proc /tmp/maps.black/proc
  mkdir -p /tmp/maps.black/usr/local/0-9se/sites/maps.black /tmp/maps.black/usr/local/0-9se/sites/.maps.black
  cp -r ./* /tmp/maps.black/usr/local/0-9se/sites/.maps.black/
  rm -f /tmp/maps.black/usr/local/0-9se/sites/.maps.black/maps.black.raw

  chroot /tmp/maps.black /bin/bash -c "
set -xeuo pipefail
apt update && apt upgrade -y
apt install -y ca-certificates systemd curl python3 python-is-python3 python3-venv libgeos-dev squashfs-tools erofs-utils build-essential libboost-all-dev cmake clang libfreetype-dev parallel unzip zip moreutils optipng sqlite3 jq uuid-runtime gcc g++ make libsqlite3-dev zlib1g-dev pngquant webp tmux git gdal-bin fonttools pkg-config brotli rsync btrfs-progs

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "/root/.cargo/env"
cargo install oxipng

curl --proto '=https' --tlsv1.2 -sSf -L https://deb.nodesource.com/setup_23.x | sh
apt install -y nodejs
cd /usr/local/0-9se/sites/.maps.black/apps/ && . ./build.sh && build
cd /usr/local/0-9se/sites/.maps.black/client/ && npm ci
cd /usr/local/0-9se/sites/.maps.black/naturalearth-vector/ && npm ci
apt clean autoclean && apt autoremove --yes && rm -rf /var/lib/apt/lists/*
"
  umount /tmp/maps.black/proc || true
  touch /tmp/maps.black/etc/machine-id /tmp/maps.black/etc/resolv.conf

  cat >"/tmp/maps.black/etc/systemd/system/maps.black-build.service" <<EOF
[Unit]
Description="maps.black build"
After=network-online.target
Requires=network-online.target

[Service]
Type=oneshot
BindPaths=/usr/local/0-9se/sites/maps.black
WorkingDirectory=/usr/local/0-9se/sites/maps.black
ExecStart=/usr/local/0-9se/sites/.maps.black/build.sh prep
ExecStart=/usr/local/0-9se/sites/maps.black/build.sh build

[Install]
WantedBy=multi-user.target
EOF
  cat >"/tmp/maps.black/etc/systemd/system/maps.black-build-full.service" <<EOF
[Unit]
Description="maps.black build full"
After=network-online.target
Requires=network-online.target

[Service]
Type=oneshot
BindPaths=/usr/local/0-9se/sites/maps.black
WorkingDirectory=/usr/local/0-9se/sites/maps.black
ExecStart=/usr/local/0-9se/sites/.maps.black/build.sh prep
ExecStart=/usr/local/0-9se/sites/maps.black/build.sh build_full

[Install]
WantedBy=multi-user.target
EOF
  cat >"/tmp/maps.black/etc/systemd/system/maps.black-build.timer" <<EOF
[Unit]
Description="maps.black build timer"
After=network-online.target
Requires=network-online.target

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
EOF

  # Package the files
  rm -f ./maps.black.raw
  find /tmp/maps.black/ -type d -exec chmod 777 {} \;
  mksquashfs /tmp/maps.black/ ./maps.black.raw -comp zstd -no-xattrs -all-root -info -progress -no-exports -Xcompression-level 6
  rm -rf /tmp/maps.black/
  du -sh --apparent-size ./maps.black.raw
}
export -f build_image
