#!/bin/bash

set -e

CONFIG_FILE="$1"
KEY="$2"
SECRET="$3"
ENDPOINT="$4"
BUCKET="$5"


KEY="$1"
SECRET="$2"
ENDPOINT="$3"
BUCKET="$4"
FILEPATH="$5"
FILENAME="$6"

echo -e "
#----------------------#
# INSTALL DEPENDENCIES #
#----------------------#
"

apt-get update
apt-get install -y curl

echo -e "
#-------------#
# UPLOAD FILE #
#-------------#
"
curl -v --location --header 'x-amz-auto-make-bucket:1' \
     --header 'x-archive-meta01-collection:opensource' \
     --header "authorization: LOW ${KEY}:${SECRET}" \
     --upload-file "$FILEPATH" \
     "$ENDPOINT"/"$BUCKET"/"$FILENAME" || exit 1
