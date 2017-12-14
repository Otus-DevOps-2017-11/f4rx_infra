#!/bin/bash

# скрипт install_mongodb.sh - должен содержать команды по установке MongoDB

set -e

err_report() {
  echo "errexit on line $(caller)" >&2
}

trap err_report ERR

echo "Install mongo"
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt install -y mongodb-org

echo "Start mongo"
sudo systemctl start mongod
sudo systemctl enable mongod

echo "Check mongo"
pgrep mongod
