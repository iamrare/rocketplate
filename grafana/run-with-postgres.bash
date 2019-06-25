#!/bin/bash

# Copied from https://stackoverflow.com/a/39028690/663001

echo "Connecting to $GF_DATABASE_URL"

retries=30

printf "Connecting to postgres"
until psql $GF_DATABASE_URL -c "select 1" > /dev/null 2>&1 || [ $retries -eq 0 ]; do
  printf "."
  retries=$(($retries-1))
  sleep 1
done

if [[ $retries == 0 ]]; then
  echo ""
  echo "Couldn't connect to postgres"
  exit 1
fi

/run.sh "$@"
