#!/bin/bash

# Copied from https://stackoverflow.com/a/39028690/663001

retries=30

printf "Connecting to postgres"
until psql postgres://$RAMBLER_USER:$RAMBLER_PASSWORD@$RAMBLER_HOST:5432/$RAMBLER_DATABASE -c "select 1" > /dev/null 2>&1 || [ $retries -eq 0 ]; do
  printf "."
  retries=$(($retries-1))
  sleep 1
done

if [[ $retries == 0 ]]; then
  echo ""
  echo "Couldn't connect to postgres"
  exit 1
fi

rambler --debug apply -a
