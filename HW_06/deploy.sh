#!/bin/bash

# • скрипт deploy.sh должен содержать команды скачивания кода, установки зависимостей через bundler и запуск приложения.

set -e

err_report() {
  echo "errexit on line $(caller)" >&2
}

trap err_report ERR

if [[ $EUID -eq 0 ]]; then
   echo "This script must be run as unprivileged user" 1>&2
   exit 1
fi

echo "Cloning repo"
cd ~/
git clone https://github.com/Otus-DevOps-2017-11/reddit.git
cd reddit/
echo "Install dependencies"
bundle install
echo "Start daemon"
puma -d
echo "Check puma server"
sleep 3
pgrep -f "puma"
