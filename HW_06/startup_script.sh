#!/bin/bash

git clone https://github.com/Otus-DevOps-2017-11/f4rx_infra.git && \
cd f4rx_infra && \
git checkout Infra-2 && \
./HW_06/install_ruby.sh && \
./HW_06/install_mongodb.sh && \
./HW_06/deploy.sh