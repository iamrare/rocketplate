#!/bin/bash

TF_STATE_PREFIX=tfvars/

if [[ -z $1 ]]; then
  cat <<EOF
Usage: ./tfvars.bash [COMMAND]

Commands:
  upload
  download
EOF
  exit 1
fi

if [[ ( -z "$STAGE" ) || ( -z "$TF_BUCKET" ) ]]; then
  echo 'Missing $STAGE or $TF_BUCKET environment variables, aborting.'
  exit 1
fi

if [[ ($1 != 'download') && ($1 != 'upload') ]]; then
  echo 'Second argument must be "download" or "upload."'
  exit 1
fi

if [[ $1 == 'upload' ]]; then
  gsutil cp $STAGE.tfvars gs://$TF_BUCKET/$TF_STATE_PREFIX
  exit 0
fi

if [[ $1 == 'download' ]]; then
  if [[ -f "./$STAGE.tfvars" ]]; then
    echo "$STAGE.tfvars already exists, are you sure you want to overwrite? Type \"yes\""
    read answer
    if [[ $answer != 'yes' ]]; then
      echo '"yes" not typed, aborting.'
      exit 1
    fi
  fi

  gsutil cp gs://$TF_BUCKET/$TF_STATE_PREFIX$STAGE.tfvars $STAGE.tfvars
  exit 0
fi
