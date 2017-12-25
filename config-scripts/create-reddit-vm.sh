#!/bin/bash

set -e

err_report() {
  echo "errexit on line $(caller)" >&2
}

trap err_report ERR

if [ -z "$1" ]
then
    APP_NAME="reddit-app-hw-07"
else
    APP_NAME="${1}"
fi

gcloud compute instances create "${APP_NAME}" \
--boot-disk-size=10GB \
--tags puma-server \
--restart-on-failure \
--zone=europe-west1-b \
--machine-type=f1-micro \
--image-family reddit-full

