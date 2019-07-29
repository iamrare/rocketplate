#!/bin/bash

if [[ -z $1 ]]; then
  cat <<EOF
Use this to bootstrap the google cloud storage for both terraform state and
terraform variable files.

Usage: ./bootstrap.bash TERRAFORM_BUCKET_NAME
EOF
  exit 1
fi

gsutil mb -c regional -l us-west2 gs://$1/
gsutil versioning set on gs://$1/

project_id=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
project_number=$(gcloud projects describe $(gcloud config list --format 'value(core.project)' 2>/dev/null) --format 'value(projectNumber)')

echo $project_id
echo $project_number

if [[ ( -z "$project_id" ) && ( -z "$project_number" ) ]]; then
  echo "Current project not found. Can't configure Cloud Build service account. Make sure gcloud is authenticated and has project set."
  exit 1
fi

gcloud services enable cloudbuild.googleapis.com
gcloud services enable dns.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable cloudfunctions.googleapis.com

cloudbuild_service_account=$project_number@cloudbuild.gserviceaccount.com

gcloud projects add-iam-policy-binding $project_id \
  --member serviceAccount:$cloudbuild_service_account \
  --role roles/container.admin

gcloud projects add-iam-policy-binding $project_id \
  --member serviceAccount:$cloudbuild_service_account \
  --role roles/compute.networkAdmin

gcloud projects add-iam-policy-binding $project_id \
  --member serviceAccount:$cloudbuild_service_account \
  --role roles/dns.admin

gcloud projects add-iam-policy-binding $project_id \
  --member serviceAccount:$cloudbuild_service_account \
  --role roles/cloudsql.admin

echo ""
echo "Done! To simplify the rest of the commands, run:"
echo ""
echo "  export TF_BUCKET=$1"
