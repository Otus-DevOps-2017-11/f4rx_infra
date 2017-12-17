#!/bin/bash

# • скрипт deploy.sh должен содержать команды скачивания кода, установки зависимостей через bundler и запуск приложения.

set -e

err_report() {
  echo "errexit on line $(caller)" >&2
}

trap err_report ERR

if [ -z "$1" ]
then
    WORK_DIR="~/"
else
    WORK_DIR="${1}"
fi

echo "Cloning repo"
cd $WORK_DIR
git clone https://github.com/Otus-DevOps-2017-11/reddit.git
cd reddit/
echo "Install dependencies"
bundle install
