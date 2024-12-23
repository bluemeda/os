#!/bin/bash

set -e

CONFIG_FILE="$1"
KEY="$2"
SECRET="$3"
ENDPOINT="$4"
BUCKET="$5"

source "$CONFIG_FILE"

echo -e "
#----------------------#
# INSTALL DEPENDENCIES #
#----------------------#
"

apt-get update
apt-get install -y curl

echo -e "
#------------#
# UPLOAD ISO #
#------------#
"

# get the paths & filenames of the files to upload
ISOPATHS="$(find builds -name "*.iso")"
while IFS= read -r ISOPATH; do
  SHAPATH="${ISOPATH%.*}.sha256.txt"
  MD5PATH="${ISOPATH%.*}.md5.txt"
  ISO="$CHANNEL/$(basename "$ISOPATH")"
  SHASUM="$CHANNEL/$(basename "$SHAPATH")"
  MD5="$CHANNEL/$(basename "$MD5PATH")"
  echo "uploading $ISO..."
  curl --location --header 'x-amz-auto-make-bucket:1' \
     --header 'x-archive-meta01-collection:opensource' \
     --header "authorization: LOW ${KEY}:${SECRET}" \
     --upload-file "$ISOPATH" \
     "$ENDPOINT"/"$BUCKET"/"$ISO" || exit 1
  echo "uploading $SHASUM..."
  curl --location --header 'x-amz-auto-make-bucket:1' \
     --header 'x-archive-meta01-collection:opensource' \
     --header "authorization: LOW ${KEY}:${SECRET}" \
     --upload-file "$SHAPATH" \
     "$ENDPOINT"/"$BUCKET"/"$SHASUM" || exit 1
  echo "uploading $MD5..."
  curl --location --header 'x-amz-auto-make-bucket:1' \
     --header 'x-archive-meta01-collection:opensource' \
     --header "authorization: LOW ${KEY}:${SECRET}" \
     --upload-file "$MD5PATH" \
     "$ENDPOINT"/"$BUCKET"/"$MD5" || exit 1

  if [ "$CHANNEL" == "stable" ]; then
    # install transmission
    apt-get install -y transmission-cli
    cd "$(dirname "$ISOPATH")" || exit 1
    # create torrent file
    transmission-create "$(basename "$ISOPATH")" \
      -t https://ashrise.com:443/phoenix/announce \
      -t udp://open.demonii.com:1337/announce \
      -t udp://tracker.ccc.de:80/announce \
      -t udp://tracker.istole.it:80/announce \
      -t udp://tracker.openbittorrent.com:80/announce \
      -t udp://tracker.publicbt.com:80/announce
    cd ~- || exit 1
    echo "uploading $ISO.torrent..."
    python3 upload.py "$KEY" "$SECRET" "$ENDPOINT" "$BUCKET" "$ISOPATH.torrent" "$ISO.torrent" || exit 1

  fi
done <<< "$ISOPATHS"
