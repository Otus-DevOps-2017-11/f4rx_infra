#!/bin/bash

useradd -m puma

cd ~/
git clone https://github.com/Otus-DevOps-2017-11/f4rx_infra.git && \
cd f4rx_infra && \
git checkout Infra-2 && \
./HW_06/install_ruby.sh && \
./HW_06/install_mongodb.sh && \
./HW_06/deploy.sh "/home/puma" && \
cp ./HW_06/puma_startup.sh /tmp/ && \

sudo -i -u puma /tmp/puma_startup.sh && \

echo "0" > /tmp/puma_install_status || \
echo "1" > /tmp/puma_install_status