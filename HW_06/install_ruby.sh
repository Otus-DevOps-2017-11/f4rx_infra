#!/bin/bash

# • скрипт install_ruby.sh - должен содержать команды по установке руби.

set -e

err_report() {
  echo "errexit on line $(caller)" >&2
}

trap err_report ERR

echo "Executing `apt update`"
sudo apt update
echo "Executing `apt install -y ruby-full ruby-bundler build-essential`"
apt install -y ruby-full ruby-bundler build-essential
