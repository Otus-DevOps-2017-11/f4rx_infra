#!/bin/bash

# запуск сервиса puma. Вынесено в отдельный ск

set -e

err_report() {
  echo "errexit on line $(caller)" >&2
}

trap err_report ERR

echo "Start daemon"
puma -d
echo "Check puma server"
sleep 3
pgrep -f "puma"
echo "Service puma is started"