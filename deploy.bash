#!/bin/bash

TF_STATE_PREFIX=tfstate/

if [[ ( -z "$STAGE" ) || ( -z "$TF_BUCKET" ) ]]; then
  echo 'Missing $STAGE or $TF_BUCKET environment variables, aborting.'
  exit 1
fi

[[ ! -f ./$STAGE.tfvars ]] && ./tfvars.bash download

if [[ ! -f ./$STAGE.tfvars ]]; then
  echo 'Missing tfvars for stage, aborting.'
  exit 1
fi

CLUSTER_NAME=$(cat $STAGE.tfvars | grep CLUSTER_NAME | cut -d '"' -f2)
CLUSTER_ZONE=$(cat $STAGE.tfvars | grep GOOGLE_ZONE | cut -d '"' -f2)
echo "Deploying:"
echo "  $STAGE"
echo "  $TF_BUCKET"
echo "  $CLUSTER_NAME"
echo "  $CLUSTER_ZONE"

gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE
gcloud auth configure-docker

if [[ $1 == 'remote' ]]; then
  [[ -f ./$STAGE.tfvars ]] && ./tfvars.bash upload

  gcloud builds submit \
    --config cloudbuild.yaml \
    --substitutions=_SHORT_HASH=`git rev-parse --verify --short HEAD`,_STAGE=$STAGE,_TF_BUCKET=$TF_BUCKET

else
  # Run integration tests
  ## API
  docker-compose --log-level=WARNING run api-test
  if [[ $? != '0' ]]; then
    echo "API tests failed"
    exit 1
  fi;

  terraform init \
    --backend-config=bucket=$TF_BUCKET \
    --backend-config=prefix=$TF_STATE_PREFIX$STAGE

  # Only automatically deploy certain modules, so we don't inadvertantly
  # make any destructive changes
  terraform apply -auto-approve -var-file=$STAGE.tfvars \
    -target=module.rambler \
    -target=module.api \
    -target=module.web
fi
