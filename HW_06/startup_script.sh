#!/bin/bash

cat > /tmp/install_puma.sh << 'EOF'
#!/bin/bash

cd ~/
git clone https://github.com/Otus-DevOps-2017-11/f4rx_infra.git && \
cd f4rx_infra && \
git checkout Infra-2 && \
./HW_06/install_ruby.sh && \
./HW_06/install_mongodb.sh && \
./HW_06/deploy.sh && \
touch /tmp/puma_successfully_installed.txt


EOF

sudo -i -u astepanenko bash /tmp/install_puma.sh
