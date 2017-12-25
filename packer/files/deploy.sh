#!/bin/bash

# скрипт deploy.sh должен содержать команды скачивания кода, установки зависимостей через bundler и запуск приложения.

set -euo pipefail

err_report() {
  echo "errexit on line $(caller)" >&2
}

trap err_report ERR

# For debug
set -x

echo "Create user puma"
useradd -m puma
echo "Cloning repo"
cd /home/puma
git clone https://github.com/Otus-DevOps-2017-11/reddit.git
chown -R puma:puma /home/puma/reddit
cd reddit/
echo "Install dependencies"
bundle install

systemctl daemon-reload
systemctl enable puma.service
systemctl start puma.service

echo "Check puma server"
sleep 3
pgrep -f "puma"
echo "Service puma is started"
