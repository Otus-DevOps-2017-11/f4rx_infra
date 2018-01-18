[![Build Status](https://travis-ci.org/Otus-DevOps-2017-11/f4rx_infra.svg?branch=ansible-3)](https://travis-ci.org/Otus-DevOps-2017-11/f4rx_infra)

# Aleksey Stepanenko 
Table of Contents
=================

   * [Aleksey Stepanenko](#aleksey-stepanenko)
   * [Table of Contents](#table-of-contents)
   * [HW 12 Ansible-3](#hw-12-ansible-3)
      * [Основное задание](#Основное-задание)
      * [ДЗ * (Dynamic Inventory   Environment)](#ДЗ--dynamic-inventory--environment)
      * [ДЗ ** (Travis-CI)](#ДЗ--travis-ci)
   * [HW 11 Ansible-2](#hw-11-ansible-2)
      * [Основное задание](#Основное-задание-1)
      * [Packer](#packer)
      * [ДЗ * (Dynamic Inventory GCP)](#ДЗ--dynamic-inventory-gcp)
         * [GCE Module](#gce-module)
         * [terraform-inventory](#terraform-inventory)
   * [HW 10 Ansible-1](#hw-10-ansible-1)
      * [Основное задание](#Основное-задание-2)
      * [ДЗ* (json-inventory)](#ДЗ-json-inventory)
   * [HW 9 Terraform-2](#hw-9-terraform-2)
      * [Несколько VM](#Несколько-vm)
      * [ДЗ * (google storage для хранения стейтов)](#ДЗ--google-storage-для-хранения-стейтов)
      * [ДЗ ** (использование теплейтов системных конфигов в модулях)](#ДЗ--использование-теплейтов-системных-конфигов-в-модулях)
         * [Основная часть](#Основная-часть)
         * [Идея которая не взлетела](#Идея-которая-не-взлетела)
      * [PS](#ps)
   * [HW 8 Terraform-1](#hw-8-terraform-1)
      * [ДЗ](#ДЗ)
      * [ДЗ *](#ДЗ-)
      * [ДЗ **](#ДЗ--1)
   * [HW 7 Packer](#hw-7-packer)
      * [ДЗ 1](#ДЗ-1)
      * [ДЗ *](#ДЗ--2)
      * [ДЗ **](#ДЗ--3)
   * [HW 6](#hw-6)
   * [HW 5](#hw-5)
      * [Otus DevOps HW 5 by Aleksey Stepanenko](#otus-devops-hw-5-by-aleksey-stepanenko)
         * [Описание стенда](#Описание-стенда)
         * [ДЗ со слайда 36](#ДЗ-со-слайда-36)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# HW 12 Ansible-3

## Основное задание

Каких-то вопросов у меня не возникло. Просто идти по методичке.  
Но в голова начинает гудеть от кучи каталог и структур. С этим ничено не поделать - надо привыкать и хорошо, что материал
подан порциями.

Команда, чтобы из вывода терраформа записать адреса хосттов в инвентори
```bash
APP_IP=$(terraform output | grep app_external_ip | awk '{print $3}') &&\
DB_IP=$(terraform output | grep db_external_ip | awk '{print $3}') &&\
sed -i '' "s/appserver ansible_host=.*$/appserver ansible_host=${APP_IP}/g" ../../ansible/inventory &&\
sed -i '' "s/dbserver ansible_host=.*$/dbserver ansible_host=${DB_IP}/g" ../../ansible/inventory
```

Команда, чтобы из вывода терраформа записать адреса хосттов в инвентори, когда мы работает с окружениями. Надо поменять 
ENV_APP перед копированием.
```bash
ENV_APP="stage" && \
APP_IP=$(terraform output | grep app_external_ip | awk '{print $3}') &&\
DB_IP=$(terraform output | grep db_external_ip | awk '{print $3}') &&\
DB_INTERNAL_IP=$(terraform output | grep db_internal_ip | awk '{print $3}') &&\
sed -i '' "s/appserver ansible_host=.*$/appserver ansible_host=${APP_IP}/g" ../../ansible/environments/${ENV_APP}/inventory &&\
sed -i '' "s/dbserver ansible_host=.*$/dbserver ansible_host=${DB_IP}/g" ../../ansible/environments/${ENV_APP}/inventory &&\
sed -i '' "s/db_host:.*$/db_host: ${DB_INTERNAL_IP}/g" ../../ansible/environments/${ENV_APP}/group_vars/app
```

Команды для себя
```bash
$ ansible-galaxy -h
$ ansible-galaxy init app
$ ansible-galaxy init db
$ ansible-playbook site.yml --check
$ ansible-playbook site.yml


$ ansible-playbook -i environments/prod/inventory deploy.yml 


$ ansible-playbook -i environments/prod/inventory playbooks/site.yml --check
$ ansible-playbook -i environments/prod/inventory playbooks/site.yml

$ ansible-playbook playbooks/site.yml
```

Правило в терраформе для nginx и 80-го порта
```hcl-terraform
resource "google_compute_firewall" "firewall_puma_nginx_80" {
  name    = "allow-puma-nginx-80"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}
```

## ДЗ * (Dynamic Inventory + Environment)

Я решил использовать динамический инвентарь от терраформа.

Сначала я не понял задание, прогнал в первый раз энсибл и увидел надпись, что у нас хост в **local environment** и понял
что надо как-то заставить работать group_vars.
```bash
TASK [db : Show info about the env this host belongs to] ***************************************************************************************************************************************************
ok: [104.199.18.115] => {
    "msg": "This host is in local environment!!!"
}
``` 
В доке написано, что все работает, если запускать инвентори из директории 
с переменными. Можно сделать ссылку, но мне кажется ссылка будет зависить от Mac/Linux - поэтому я решил сделать простенький
враппер на баше - environments/\[prod|stage]/terraform-inventory
ANSIBLE_ENV - имя окружения. Можно в принципе взять из каталога, в котором лежит terraform-inventory, но решил пока 
не усложнять
```bash
#!/usr/bin/env bash
ANSIBLE_ENV="stage"
TF_STATE=../terraform/${ANSIBLE_ENV}/terraform.tfstate terraform-inventory $1

```

Создаем окружение через terraform и проверяем
```bash
f3ex at MacBook-Pro-f3ex in ~/otus/DevOps/hw05-06_GCP/f4rx_infra/ansible (ansible-3●●●)
$ environments/stage/terraform-inventory --list
{"app":["35.195.92.60"],"app.0":["35.195.92.60"],"db":["104.199.18.115"],"db.0":["104.199.18.115"],"type_google_compute_instance":["35.195.92.60","104.199.18.115"]}%

f3ex at MacBook-Pro-f3ex in ~/otus/DevOps/hw05-06_GCP/f4rx_infra/ansible (ansible-3●●●)
$ ansible-playbook -i environments/stage/terraform-inventory playbooks/site.yml
....
TASK [db : Show info about the env this host belongs to] ***************************************************************************************************************************************************
ok: [104.199.18.115] => {
    "msg": "This host is in stage environment!!!"
}
...

# Пересоздаем окружение в терраформе  проверяем

f3ex at MacBook-Pro-f3ex in ~/otus/DevOps/hw05-06_GCP/f4rx_infra/ansible (ansible-3●●●)
$ ansible-playbook -i environments/prod/terraform-inventory playbooks/site.yml
...
TASK [db : Show info about the env this host belongs to] ***************************************************************************************************************************************************
ok: [104.199.18.115] => {
    "msg": "This host is in prod environment!!!"
}
```



## ДЗ ** (Travis-CI)

С одной стороны задание простое, но пришлось потратить время на поиск примеров и вообще перечитать хабр и офф доки по тревису.  
Так же были проблемы с билдом, оставил комментарии в файле .travis.yaml

Очень много времени потратил на такую конструкцию:
```yaml
  - |
    cat > ./terraform.tfvars << '  EOF'
    project = "infra-188921"
    public_key_path = "~/.ssh/appuser.pub"
    private_key_path = "~/.ssh/appuser"
    EOF
```
EOF не срабатывал, т.к. в последней строке было '  EOF', т.е. два пробела, а блок влево сдвинуть нельзя. Так что тут << '  EOF' это костылик.
Хотя люди так делают https://github.com/mneuhaus/Famelo.Messaging/blob/master/.travis.yml 

Линтер для тревиса
```bash
$ travis lint .travis.yml
Warnings for .travis.yml:
[x] has multiple install entries, keeping last entry
```

Ссылочка для себя:
* https://github.com/mschuchard/linter-packer-validate/blob/master/.travis.yml

# HW 11 Ansible-2

## Основное задание

Отключил в терраформе блоки провижининга, отвечающие за деплой приложения в рамках ДЗ-08 со звездочкой.

Задание сделано по инструкции. Основные минусы вижу на текущем этапе:
* все yaml файлы в одно директории, что усложняет чтение и понимание текущей структуры
* мешанина в templates/files. Я бы перешел к чему-нибудь такому "tempalates/[group|host|module|playbook]/\<FS\>/file.conf", к примеру
"templates/mongo_db/etc/mongod.conf.j2"
* Важные конфиги, точнее переменные, которые относятся к хостам, задаем в плейбуке. К примеру внутреннеий адрес DB-сервера. Я бы вынес его повыше. (Наверно это будет дальше)
* IP-адрес DB-сервера мы указываем руками.

Каких-то трудностей не возникло, но задание хоть и хорошее, но несколько нудное и тяжеловато, в голове нужно много чего
держать. Потратил где-то часов 6 на него.

Как собрать проект
```bash
# Собираем инфрастуктуру
cd terraform/stage

terraform apply
..
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

app_external_ip = 104.199.83.33
db_external_ip = 104.199.24.20
db_internal_ip = 10.132.0.2


# Запускаем Anisble
cd ../../ansible

# Правим IP хостов
vim inventory

# Проверяем, что хосты доступны
ansible all -m ping
dbserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
appserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

# Проверяем и применяем конфигурацию
ansible-playbook site.yml --check

ansible-playbook site.yml
...
appserver                  : ok=9    changed=7    unreachable=0    failed=0
dbserver                   : ok=3    changed=2    unreachable=0    failed=0

# Проверяем в браузере, что все ок
http://104.199.83.33:9292

# Разбираем стенд
cd ../terraform/stage

terraform destroy
```

Команды
```bash
$ ansible-playbook reddit_app.yml --check --limit db

PLAY [Configure hosts & deploy application] ********

TASK [Gathering Facts] *****************************
ok: [dbserver]

TASK [Change mongo config file] ********************
changed: [dbserver]

RUNNING HANDLER [restart mongod] *******************
changed: [dbserver]

PLAY RECAP *****************************************
dbserver                   : ok=3    changed=2    unreachable=0    failed=0



$ ansible-playbook reddit_app.yml --limit db

PLAY [Configure hosts & deploy application] ********

TASK [Gathering Facts] *****************************
ok: [dbserver]

TASK [Change mongo config file] ********************
changed: [dbserver]

RUNNING HANDLER [restart mongod] *******************
changed: [dbserver]

PLAY RECAP *****************************************
dbserver                   : ok=3    changed=2    unreachable=0    failed=0

$ ansible-playbook reddit_app.yml --check --limit app --tags app-tag
```

После разбиения на плеи

```bash
ansible-playbook reddit_app2.yml --tags db-tag --check

ansible-playbook reddit_app2.yml --tags db-tag 
```

## Packer

Замечание, пакер работает только при развернутом окружение из терраформа, т.к. там создается правило фаервола, которое
позволяет зайти на 22-й порт по ssh. Т.е. тег навешивать мы тут умеем, но правила еще нет.

В **packer_db.yaml** мой эксперимент, чтобы не указывать **-name**. Считаю лишним писать какое-то пояснение типа "создаю 
файл" и вызывать модуль file touch.

```bash
f3ex at MacBook-Pro-f3ex in ~/otus/DevOps/hw05-06_GCP/f4rx_infra (ansible-2●●)
$ packer build -var-file=packer/variables.json packer/app.json
...
==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: reddit-app-base-1515955437

f3ex at MacBook-Pro-f3ex in ~/otus/DevOps/hw05-06_GCP/f4rx_infra (ansible-2●●)
$ packer build -var-file=packer/variables.json packer/db.json
...
==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: reddit-db-base-1515959151
```

Я не нашел в логах GCP как проверить точно из какого образа создан инстанс, если мы используем image family в пакере. 
Поэтому добавил такое задание:
```yaml
  vars:
    date: "{{ lookup('pipe', 'date +%Y%m%d-%H%M') }}"
...
    - name: Set Date
      lineinfile:
        path: /root/build_date
        line: "{{ date }}"
```

Теперь можно получить непосредственно из ОС дату билда.

Пересоздаем терраформом стенд и выполняем энсибл
```bash
ansible-playbook site.yml --check
ansible-playbook site.yml
...
appserver                  : ok=9    changed=7    unreachable=0    failed=0
dbserver                   : ok=3    changed=2    unreachable=0    failed=0
```

Проверяем в браузере, все ок.

Проверяем, что билд свежий
```bash
$ ansible  all -m command -a "cat /root/build_date" --become
dbserver | SUCCESS | rc=0 >>
20180114-2334

appserver | SUCCESS | rc=0 >>
20180114-2329
```

## ДЗ * (Dynamic Inventory GCP)

Немного не понял задание.  
* Что именно иследовать ?
* Какие юзкейсы мы хотим охватить ?
* Какую проблемы мы вообще решаем ?
* Что мы хотим вообще тут получить ?
* Что у нас сейча болит ? Я могу перечислить в текущем проекте моментов ~10, которые плохо сделаны в текущей реализации.

### GCE Module
Офф. дока http://docs.ansible.com/ansible/latest/guide_gce.html

Сам скрипт доступен в офф репе.
```bash
https://raw.githubusercontent.com/ansible/ansible/stable-2.4/contrib/inventory/gce.py
```

На маке мне пришлось установить pycrypto
```bash
pip install pycrypto
```

модуль поддерживает три режима авторизации - создания secret.py, ini-файла или переменных окружения.  Я сделал через
переменные окружения. gcerc и gce.py приложены к репозиторию.
```bash
$ cat gcerc
export GCE_EMAIL=6..@developer.gserviceaccount.com
export GCE_PROJECT=infra-188921
export GCE_CREDENTIALS_FILE_PATH=./Infra-4..0.json

$ source gcerc
```

```bash
$ python ./gce.py --list
{"europe-west1-d": ["reddit-app", "reddit-db"], "tag_reddit-db": ["reddit-db"], "_meta": {"stats": {"cache_used": false, "inventory_load_time": 0.7172539234161377}, "hostvars": {"reddit-app": {"gce_uuid": "51af2f511545be90d02b6c7c9ee5878c2d9d251e", "gce_public_ip": "104.199.83.33", "ansible_ssh_host": "104.199.83.33", "gce_private_ip": "10.132.0.3", "gce_id": "4870079332018946333", "gce_image": "reddit-app-base-1515961598", "gce_description": null, "gce_machine_type": "g1-small", "gce_subnetwork": "default", "gce_tags": ["reddit-app"], "gce_name": "reddit-app", "gce_zone": "europe-west1-d", "gce_status": "RUNNING", "gce_network": "default", "gce_metadata": {"sshKeys": "appuser:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB+wDIhMjsBXFuepcUXNQiqGJosR3RD6tfK5m6iT8lDU9rdYjYMHHpa3IxN7djETzT+JUlAD+w3hy1H1wqpkeZwAzIu/tNgh901gIIGtHkgWuQ8b9mzI5kTSlYtQ1bdLK28uMxOjt0KBOHP64pDYVzRD7GKNVTXPYefq70iBvEgkq4M1NcZlUmP32OwVZrliZrM8JsdnmmiurjP30NvrAQSoxB+UrEfodT4qgVcQzotp2HcYHy2FLkImlcHszs9ngyy64ldqJVIVfbxLBGQqhDeEWvhh5emVdzNGgCtVb2vuz5JXxENDZm9map/vt9gTl6sB/+IJRHLCdSVkRnWk1lS/6Pbfvdsl3AImJRCYGHYaq7pM2U3FNA4TTMY2vJAsjo8uhg098twUNj3MAkfHVUoaoPoNQDt7RLA59hbf00YmeumhZz73jBQGHiVH3jq2E79nYDkzWhr8Kne/TxDaUExsw8rKZpBjY8WE2K9sIhYLoEsPklJExxZDOeYBlFADhynbK2XEoD1vtYpfge7ITgcmUIh91/K341qkNfVnUDIoN5lV+SeYN28c/HJEKXGGPsog1/vCBWPC23z22K8Pe+WqBHba8jbG+OItlyBh00trQe9mEnB5XxSabPeDXJv3bfnh1lOT5V9X+Wjfx0SlD7v69XcWDWnMhIf2dzQw== appuser\n"}}, "reddit-db": {"gce_uuid": "f05d5b75d2486ba336d35d98c46a3ca4bcabe3fd", "gce_public_ip": "104.199.24.20", "ansible_ssh_host": "104.199.24.20", "gce_private_ip": "10.132.0.2", "gce_id": "2408157962887889160", "gce_image": "reddit-db-base-1515961898", "gce_description": null, "gce_machine_type": "g1-small", "gce_subnetwork": "default", "gce_tags": ["reddit-db"], "gce_name": "reddit-db", "gce_zone": "europe-west1-d", "gce_status": "RUNNING", "gce_network": "default", "gce_metadata": {"sshKeys": "appuser:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB+wDIhMjsBXFuepcUXNQiqGJosR3RD6tfK5m6iT8lDU9rdYjYMHHpa3IxN7djETzT+JUlAD+w3hy1H1wqpkeZwAzIu/tNgh901gIIGtHkgWuQ8b9mzI5kTSlYtQ1bdLK28uMxOjt0KBOHP64pDYVzRD7GKNVTXPYefq70iBvEgkq4M1NcZlUmP32OwVZrliZrM8JsdnmmiurjP30NvrAQSoxB+UrEfodT4qgVcQzotp2HcYHy2FLkImlcHszs9ngyy64ldqJVIVfbxLBGQqhDeEWvhh5emVdzNGgCtVb2vuz5JXxENDZm9map/vt9gTl6sB/+IJRHLCdSVkRnWk1lS/6Pbfvdsl3AImJRCYGHYaq7pM2U3FNA4TTMY2vJAsjo8uhg098twUNj3MAkfHVUoaoPoNQDt7RLA59hbf00YmeumhZz73jBQGHiVH3jq2E79nYDkzWhr8Kne/TxDaUExsw8rKZpBjY8WE2K9sIhYLoEsPklJExxZDOeYBlFADhynbK2XEoD1vtYpfge7ITgcmUIh91/K341qkNfVnUDIoN5lV+SeYN28c/HJEKXGGPsog1/vCBWPC23z22K8Pe+WqBHba8jbG+OItlyBh00trQe9mEnB5XxSabPeDXJv3bfnh1lOT5V9X+Wjfx0SlD7v69XcWDWnMhIf2dzQw== appuser\n"}}}}, "tag_reddit-app": ["reddit-app"], "10.132.0.2": ["reddit-db"], "status_running": ["reddit-app", "reddit-db"], "g1-small": ["reddit-app", "reddit-db"], "104.199.83.33": ["reddit-app"], "104.199.24.20": ["reddit-db"], "10.132.0.3": ["reddit-app"], "reddit-app-base-1515961598": ["reddit-app"], "reddit-db-base-1515961898": ["reddit-db"], "network_default": ["reddit-app", "reddit-db"]}
```

```bash
$ ansible all -i gce.py -m ping
reddit-db | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
reddit-app | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

В таком сценарии не вижу какого-то практического применения, ну разве только получить список хостов. Т.е. в таком подходе
получается мы как бы уже после узнаем об инфраструктуре. Т.е. правая рука не знает, что делает левая. Я бы тогда больше 
топил за то, чтобы и хосты создавать/поднимать через ansible.

### terraform-inventory
У коллеги (enkov) подсмотрел ссылку на https://github.com/adammck/terraform-inventory  
**Замечание** Т.к. для работы нужен state file, то я отключил хранение стейтов в бакете.  

Установка на маке
```bash
$ brew install terraform-inventory
```
Проверяем
```bash
$ terraform-inventory --list
{"app":["35.195.212.69"],"app.0":["35.195.212.69"],"db":["146.148.123.181"],"db.0":["146.148.123.181"],"type_google_compute_instance":["35.195.212.69","146.148.123.181"]}
```

```bash
$ TF_STATE=../terraform/stage/terraform.tfstate ansible -i /usr/local/bin/terraform-inventory all -m ping
35.195.212.69 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
146.148.123.181 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Решение кажется более интересным. Но пока не вижу сценариев для использования.

# HW 10 Ansible-1

## Основное задание
С Ansbible чутка знаком, но я работаю с паппетом (в трух компаниях где я был - был только паппет). Каких-то 
вопросов/замечаний у меня не возникло.

Установка Ansible
```bash
sudo -H pip install -r requirements.txt
```

Все хосты доступны
```bash
$ ansible all -m ping
dbserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
appserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Напишу команды для себя, для истории
```bash
$ ansible all -m command -a uptime
appserver | SUCCESS | rc=0 >>
 07:52:52 up 11:39,  1 user,  load average: 0.00, 0.00, 0.00

dbserver | SUCCESS | rc=0 >>
 07:52:52 up 11:58,  1 user,  load average: 0.00, 0.01, 0.00
```

```bash
$ ansible app -m shell -a 'ruby -v; bundler -v'
appserver | SUCCESS | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
Bundler version 1.11.2
```

## ДЗ* (json-inventory)

Я сначала пошел создавать json файл, даже скачал конвертилку (вот этого товарища https://gist.github.com/sivel/3c0745243787b9899486).  
Собственно применить json файл нельзя - я получал ошибку, что пробует плагин ini или yaml, json там не было. И я решил 
проверить плагины инвентаря.
```bash
$ ansible-doc -t inventory -l
advanced_host_list Parses a 'host list' with ranges
constructed        Uses Jinja2 to construct vars and groups based on existing inventory.
host_list          Parses a 'host list' string
ini                Uses an Ansible INI file as inventory source.
openstack          OpenStack inventory source
script             Executes an inventory script that returns JSON
virtualbox         virtualbox inventory source
yaml               Uses a specifically YAML file as inventory source.
```

И тут нет json, а для  json они хотят скрипт, который возвращает json. В общем я подправил скрипт, чтобы он загружал 
данные из инвентори файла, а не из аргумента, и все заработало.

```bash
$ diff 1.py inventory2json.py
diff --git a/1.py b/inventory2json.py
old mode 100644
new mode 100755
index bf43167..29cb702
--- a/1.py
+++ b/inventory2json.py
@@ -1,3 +1,5 @@
+#!/usr/bin/env python
+
 import sys
 import json

@@ -11,13 +13,15 @@ except ImportError:
     from ansible.inventory import Inventory
     A24 = False

+inventory_file = "./inventory"
+
 loader = DataLoader()
 if A24:
-    inventory = InventoryManager(loader, [sys.argv[1]])
+    inventory = InventoryManager(loader, inventory_file)
     inventory.parse_sources()
 else:
     variable_manager = VariableManager()
-    inventory = Inventory(loader, variable_manager, sys.argv[1])
+    inventory = Inventory(loader, variable_manager, inventory_file)
     inventory.parse_inventory(inventory.host_list)

 out = {'_meta': {'hostvars': {}}}
```

```bash
$ ansible -i inventory2json.py all -m ping
appserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

# HW 9 Terraform-2

В данном задание ВМ была разбита на две (по функциональности), ВМ вынесены в модули и созданы два окружения.  
**Замечание.** stage и prod окружения не будут работать вместе из-за одинаковыех названий ВМ и правил FW. Решеним для меня было бы
разнести их по разным Проектам в GCP  
Создан **storage-bucket.tf** управление бакитами (google storage) через терраформ путем инсталяции стороннего модуля.

Результат работы поедставлен в виде модулей (modulss/app, modules/db, modules/vpc) и двух энвариментов/стендов/контуров
prod/stage  
Запуск проект происходит в директории stage/prod. Перед запуском можно скопировать файл с переменными terraform.tvars.example
в terraform.tvars и задать переменную **project**. В случае со стендом stage нужно еще создать бакет в консоли GCP
и указать бакет в переменной backend_gcp_backet для использования Google Storage в качестве хранилиза стейтов 
(для совместной работы). Переменну bucket в бекенде нельзя параметризовать, поэтому нужно изменить значение в **backend.tf**
до первого запуска.

Используемые команды:
```bash
# установка модулей
terraform get
# установка плагинов
terragorm init
```

График зависимостей
```bash
terraform graph | dot -Tpng > graph.png
```
![График зависимостей](images/graph.png?raw=true "График зависимостей")

## Несколько VM
Собираем пакером:
```bash
cd packer
packer build -var-file=variables.json app.json
packer build -var-file=variables.json db.json
```

## ДЗ * (google storage для хранения стейтов)
На вкладке https://console.cloud.google.com/storage/browser?project=infra-188921 создаем сегмент (сторадж)
TODO поискать как создать storage через gcloud

Сделано только в **stage**, создан файл **backend.tf** с содержимым:
```hcl-terraform
terraform {
  backend "gcs" {
    bucket = "otus-terraform-stepanenko"
    # bucket = "${var.backend_gcp_backet}"
  }
}
```
Можно создать минимальную конфигурацию, тогда имя бакета будет запрошено в консоли при первом вызове `terrafom init`.
```hcl-terraform
terraform {
  backend "gcs" {
  }
}
```
После этого нужно запустить `terraform init`, при этом терраформ спросит - нужно ли локальные конфиги переместить в бакет.
```hcl-terraform
terraform init
```

Если запустить два terraform-процесса одновременно, то сработает лок
```bash
Error: Error loading state: writing "gs://otus-terraform-stepanenko/default.tflock" failed: googleapi: Error 412: Precondition Failed, conditionNotMet
Lock Info:
  ID:        de6bec7a-ee69-6212-8ac9-82dfc8d04cce
  Path:
  Operation: OperationTypeApply
  Who:       f3ex@MacBook-Pro-f3ex.local
  Version:   0.11.1
  Created:   2018-01-03 08:27:42.541297415 +0000 UTC
  Info:
```

## ДЗ ** (использование теплейтов системных конфигов в модулях)
### Основная часть
Задание как обычно с подвохом, т.к. я копировал примеру из слайда, то не использовал connection, из-за чего не работал provisioner
```hcl-terraform
  connection {
    type        = "ssh"
    user        = "appuser"
    private_key = "${file(var.private_key_path)}"
  }
```

При вывозе моделей добавлены следующие опции
```hcl-terraform
module "app" {
...
  private_key_path = "${var.private_key_path}"
  db_address      = "${module.db.db_internal_ip}"

}
module "db" {
...
  private_key_path = "${var.private_key_path}"
}
```

В module/app добавлен **provisioner'ы** для сетапа приложения, адрес БД подставляется через теплейт.  
```hcl-terraform
data "template_file" "pumaservice" {
  template = "${file("${path.module}/files/puma.service.tpl")}"

  vars {
    db_address = "${var.db_address}"
  }
}
...
resource "google_compute_instance" "app" {
...
  provisioner "file" {
    content = "${data.template_file.pumaservice.rendered}"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
```
В module/db добавлен **provisioner'ы** для деплоя конфига монги и ее перезапуска
```hcl-terraform
data "template_file" "mongod-config" {
  template = "${file("${path.module}/files/mongod.conf.tpl")}"

  vars {
    mongo_listen_address = "0.0.0.0"
  }
}
...
resource "google_compute_instance" "db" {
...
  provisioner "file" {
    content = "${data.template_file.mongod-config.rendered}"
    destination = "/tmp/mongod.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/mongod.conf /etc/mongod.conf",
      "sudo systemctl restart mongod",
    ]
  }
```

### Идея которая не взлетела
Тут была идея сделать связь между app и монгой через интернал сеть (10/8) и сделать темплейт с конфигом монги, где 
listen будет на локальном адресе (10/8). 
Точнее связь между Апп и БД идет через 10-ю сеть и так. Наш фаерволл с target/source tags работает только в 10-й сети.
https://serverfault.com/questions/650519/gce-firewall-with-source-tags  
https://stackoverflow.com/questions/36724452/firewall-rules-with-tags-not-working-properly?rq=1

Попробовал собрать такую конструкцию, 
```hcl-terraform
data "template_file" "test-template" {
  template = "listen $${mongo_listen_address}:1234"
  vars {
    mongo_listen_address = "${google_compute_instance.test_vm_1.network_interface.address}"
  }
}


resource "google_compute_instance" "test_vm_1" {
...

  provisioner "file" {
    content     = "${data.template_file.test-template.rendered}"
    destination = "/tmp/test_template"
  }
}
```
Но получаю ошибку:
```bash
$ terraform plan

Error: Error asking for user input: 1 error(s) occurred:

* Cycle: google_compute_instance.test_vm_1, data.template_file.test-template
```

https://github.com/hashicorp/terraform/issues/16338 - тут говорят что так сделать не получиться.
>Hi! Unfortunately, this is not a thing you can do: the IP isn't allocated until the server is created, and the server 
can't be created until the template is created. So if the template can't be created until the IP is allocated, we've got 
a bit of a catch-22 here. One option may to be use the metadata server in your user_data script to retrieve the IP 
address as part of the startup of the instance.

Вообще конфигурирование я бы уже делал через коллекцию фактов в паппете + сам паппет. Но хотел бы услышать ваших 
коментариваев как делать по-феншую.
В настоящий момент БД закрывается от мира через внешний FW.

## PS
P.S. Добавлен скрипт https://github.com/ekalinin/github-markdown-toc для построения меню для упрашения навигация
по старому материалу, т.к. текста в Readme уже много

P.P.S. Нельзя пользоваться пакером до вызова терраформа, т.к. у пакера не будет ssh к ВМ. **TODO** Нужно будет сделать 
какой-нибудь отдельный тег для пакера с ssh и навешивать его на ВМ его во время создания образа

# HW 8 Terraform-1


Все команды выполняются в директории _terraform_
Команда, развернет две виртуальные машины, установит в них реддит, создаст группу ВМ и развернет LB.  
Адреса ВМ и LB будут отражены после выполнения команды или в **terraform show**

```bash
terraform apply  -auto-approve=true
...
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

app_external_ip = [
    35.205.229.45,
    35.205.82.109
]
lb_ip = 35.190.91.62
```
Проверка:
```bash
curl 35.205.229.45:9292
curl 35.205.82.109:9292
# Проверка ЛБ рассмотрена в главе ДЗ **
```


Разобраться стенд:
```bash
terraform destroy
```

## ДЗ 

Все изменения сделаны в **main.tf** согласно ТЗ.

Каких-то сложноестей в основной части ДЗ не возникло. Но хочется отметить, что в переменных нельзя сделать как-то так:
```hcl-terraform
variable app_zone {
  description = "App zone"
  default     = "${var.region}-c"
}
```
 
Используемые команды:
```hcl-terraform
terraform plan
terraform apply  -auto-approve=true
terraform show
terraform output
terraform fmt
```

> 2. Определите input переменную для задания версии провайдера "google"; 

**О.** Вопрос с подвохом, версию задать нельзя. Из документации:
>Interpolation is supported only for the per-provider configuration arguments. It is not supported for the special alias and version arguments.


## ДЗ *
> Какие проблемы вы обнаружили?

Ключи нужно записывать в одну строку и использовать \n в качестве разделителя, 3 ключа уже не будут поменщаться на экране
Т.к. в терраформе нет встроенных механизмов по контатенации строк, решил это через data inline template
```hcl-terraform
data "template_file" "ssh_keys" {
  template = "$${key1}\n$${key2}"
  vars {
    key1 = "appuser:${file(var.public_key_path)}"
    key2 = "appuser1:${file(var.public_key_path)}"
  }
}
...
  metadata {
    sshKeys = "${data.template_file.ssh_keys.rendered}"
  }
``` 

Если в проекте в GCP добавить ssh ключ, когда  уже есть развернутая ВМ, то он не добавится в ВМ.
Есди сделать destroy/apply, то пользователь appuser_web не появится на сервере. 

Нужно все целиком поддерживать либо через terraform или подключать паппет/LDAP


## ДЗ **
В main.tf добавлено count = 2 в ресурсе ВМ, из-за чего поменялись пути к переменным.

Это ДЗ вынесено в файл lb.tf - создание группы и создание балансера. В целом нужно больше попрактиковаться с балансировщиками.
Хочется отметить, что я бы сделал и попрактиковался бы:
1. Разворачивание ВМ из готового образа (reddit-full) и группировка по этому признаку
1. Прочитать больше про LB в целом
1. Проверка health-статусов из консоли _gcloud compute backend-services get-health_
1. Почитать больше про path_matcher и host_rule

Блок host_rule и path_matcher оставил закоментированным для себя. По-умолчанию создается:
```hcl-terraform
Хосты	Пути	Серверная ВМ
Все незаданные (по умолчанию)	Все незаданные (по умолчанию)	default-backend
```

После запуска **terraform apply  -auto-approve=true** нужно подождать пару минут, проверить можно как-то так:

```bash
# OK
$ curl -v -sLN `terraform output lb_ip` 2>&1 | head -30
* Rebuilt URL to: 35.190.65.227/
*   Trying 35.190.65.227...
* TCP_NODELAY set
* Connected to 35.190.65.227 (35.190.65.227) port 80 (#0)
> GET / HTTP/1.1
> Host: 35.190.65.227
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Content-Type: text/html;charset=utf-8
< X-XSS-Protection: 1; mode=block
< X-Content-Type-Options: nosniff
< X-Frame-Options: SAMEORIGIN
< Set-Cookie: rack.session=BAh7CEkiD3Nlc3Npb25faWQGOgZFVEkiRTQ2ZjljMTBhNzRlOGRhMzllN2E5%0ANzJlZTBkODJiMzYxMmUzZTdiN2FlM2UyMjk2ZmEzYzJkMDU5MWViZjQ0ZWYG%0AOwBGSSIJY3NyZgY7AEZJIjFGNU84ajVoUkZSSjhSOVpOZXozUkZGTG1rckNS%0AcHBxUE50bEQxeG9zTkM0PQY7AEZJIg10cmFja2luZwY7AEZ7B0kiFEhUVFBf%0AVVNFUl9BR0VOVAY7AFRJIi01NmMxYTdkOWI2YjdjZjUyMTdkNTk1YjM4MjVm%0AZDc4MjI5MmIyNGNjBjsARkkiGUhUVFBfQUNDRVBUX0xBTkdVQUdFBjsAVEki%0ALWRhMzlhM2VlNWU2YjRiMGQzMjU1YmZlZjk1NjAxODkwYWZkODA3MDkGOwBG%0A--82688938b41366df5320ca8f2c38f156c5cda770; path=/; HttpOnly
< Content-Length: 1861
< Date: Mon, 25 Dec 2017 09:21:07 GMT
< Via: 1.1 google
<
{ [1861 bytes data]
<!DOCTYPE html>
<html lang='en'>
<head>
<meta charset='utf-8'>
<meta content='IE=Edge,chrome=1' http-equiv='X-UA-Compatible'>
<meta content='width=device-width, initial-scale=1.0' name='viewport'>
<title>Monolith Reddit :: All posts</title>
<link crossorigin='anonymous' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css' integrity='sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7' rel='stylesheet' type='text/css'>
<link crossorigin='anonymous' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css' integrity='sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r' rel='stylesheet' type='text/css'>
<script crossorigin='anonymous' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js' integrity='sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS'></script>

```

```bash
# Не ОК. Могут наблюдаться 404 или 502
$ curl -v -sLN `terraform output lb_ip` 2>&1 | head -20
* Rebuilt URL to: 35.190.65.227/
*   Trying 35.190.65.227...
* TCP_NODELAY set
* Connected to 35.190.65.227 (35.190.65.227) port 80 (#0)
> GET / HTTP/1.1
> Host: 35.190.65.227
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 404 Not Found
< Content-Type: text/html; charset=UTF-8
< Referrer-Policy: no-referrer
< Content-Length: 1561
< Date: Mon, 25 Dec 2017 09:18:18 GMT
<
{ [1263 bytes data]
<!DOCTYPE html>
<html lang=en>
  <meta charset=utf-8>
  <meta name=viewport content="initial-scale=1, minimum-scale=1, width=device-width">
```

# HW 7 Packer

## ДЗ 1
Сборка образа packer'ом (тут и далее в директории packer)
```bash
packer build \
-var 'proj_id=infra-188921' \
-var 'source_image_family=ubuntu-1604-lts' \
ubuntu16.json
```
или использовать переменные из файла variables.json (за основу взять variables.json.example, 
указав proj_id и переопределив другие перемеменные при необходимости)
```bash
packer build -var-file=variables.json ubuntu16.json
```

## ДЗ *
В данном ДЗ я так же поставил перед собой цель собирать образ не на основе Ubuntu, а на основе 
reddit-base подготовленного в первом ДЗ. Поэтому у меня жестко забит в json **"source_image_family":"reddit-base"**  
Опять же так было проще для отладки, собирается не весь образ с нуля, а с последнего успешного этапа (reddit-base), 
что экономит время.

Запуск приложения сделан через unit-файл из под пользователя puma (см. puma.service), т.к. запускать приложение 
из под пользователя, у которого его sudo ALL без пароля, считаю не безопасным.
```bash
packer build -var 'proj_id=infra-188921' immutable.json
```

## ДЗ **
Созданием ВМ из командной строки с запущенным приложением. Аргументом задается имя ВМ, по-дефолту reddit-app-hw-07:
```bash
../config-scripts/create-reddit-vm.sh reddit-app-hw-07
```

или

```bash
gcloud compute instances create reddit-app-hw-07 \
--boot-disk-size=10GB \
--tags puma-server \
--restart-on-failure \
--zone=europe-west1-b \
--machine-type=f1-micro \
--image-family reddit-full
```

Проверка
```bash
IP=`gcloud compute instances describe reddit-app-hw-07 --zone=europe-west1-b | grep natIP | awk '{print $2}'`; curl -sNL "http://${IP}:9292" | head

<!DOCTYPE html>
<html lang='en'>
<head>
<meta charset='utf-8'>
<meta content='IE=Edge,chrome=1' http-equiv='X-UA-Compatible'>
<meta content='width=device-width, initial-scale=1.0' name='viewport'>
<title>Monolith Reddit :: All posts</title>
<link crossorigin='anonymous' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css' integrity='sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7' rel='stylesheet' type='text/css'>
<link crossorigin='anonymous' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css' integrity='sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r' rel='stylesheet' type='text/css'>
<script crossorigin='anonymous' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js' integrity='sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS'></script>
```


# HW 6

```
Самостоятельная работа
Команды по настройке системы и деплоя приложения нужно завернуть
в баш скрипты, чтобы не вбивать эти команды вручную:
• скрипт install_ruby.sh - должен содержать команды по установке руби.
• скрипт install_mongodb.sh - должен содержать команды по установке
MongoDB
• скрипт deploy.sh должен содержать команды скачивания кода,
установки зависимостей через bundler и запуск приложения.
Для ознакомления с базовыми принципами написания баш скриптов
можно ознакомится с переводом хорошей серии туториалов.
Как минимум, нужно чтобы итоговые баш скрипты:
• Содержали shebang в начале
• Выполняли необходимые действия
• В репозиторий были закомиченными исполняемыми файлами (+x )
```
Скрипты находятся в каталоге HW_06
Запуск приложения вынесен в скрипт puma_startup.sh, чтобы обеспечить запуск под непривилегированным пользователем puma.
Нехорошо вешать приложение в интернет с рутовыми правами  



```
Дополнительное задание
В качестве доп задания используйте созданные ранее
скрипты для создания Startup script, который будет
запускаться при создании инстанса. Передавать Startup
скрипт необходимо как доп опцию уже использованной
ранее команде gcloud. В результате применения данной
команды gcloud мы должны получать инстанс с уже
запущенным приложением. Startup скрипт необходимо
закомитить, а используемую команду gcloud вставить в
описание репозитория (README.md)
```

Запуск приложения происходит от не системного пользователя puma

Вариант 1 для запуска с использованием metadata-from-file startup-script:
```bash
gcloud compute instances create reddit-app2 \
--boot-disk-size=10GB \
--image-family ubuntu-1604-lts \
--image-project=ubuntu-os-cloud \
--machine-type=g1-small \
--tags puma-server \
--restart-on-failure \
--zone=europe-west1-b \
 --metadata-from-file startup-script=HW_06/startup_script.sh
```

Вариант 2 с использованием startup-script-url 
```bash
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --zone=europe-west3-a \
  --metadata "startup-script-url=https://raw.githubusercontent.com/Otus-DevOps-2017-11/f4rx_infra/Infra-2/HW_06/startup_script.sh"
```

# HW 5

## Otus DevOps HW 5 by Aleksey Stepanenko

### Описание стенда

Хост bastion, Внешний IP: 35.198.128.243, внутренний IP: 10.156.0.2  
Хост: someinternalhost, внутренний IP: 10.156.0.3

### ДЗ со слайда 36

Самостоятельное задание  
Исследовать способ подключения к internalhost в одну команду из вашего рабочего устройства,
проверить работоспособность найденного решения и внести его в README.md в вашем репозитории

Вариант с ProxyJump (раньше такой вариант не работал и нужно было использовать вариант с nc):
```bash
ssh -J astepanenko@35.198.128.243 astepanenko@10.156.0.3
```
Пример
```bash
$ ssh -J 35.198.128.243 10.156.0.3 -t "whoami; hostname"
astepanenko
someinternalhost
```
при этом содержимое ~/.ssh/config
```buildoutcfg
# all
Host *
ForwardAgent yes
User astepanenko
IdentityFile /Users/f3ex/.ssh/id_rsa
TCPKeepAlive yes
ServerAliveInterval 20
ServerAliveCountMax 30
ControlPath ~/.ssh/controlmasters/%r@%h:%p
ControlMaster auto
```

Доп. задание: Предложить вариант решения для подключения из консоли при помощи команды вида
ssh internalhost из локальной консоли рабочего устройства, чтобы подключение выполнялось по
алиасу internalhost и внести его в README.md в вашем репозитории

добавляем в ~/.ssh/config

```bash
Host bastion
Hostname 35.198.128.243
User astepanenko  

Host someinternalhost
Hostname 10.156.0.3
ProxyJump bastion
User astepanenko
```

теперь подключаемся одной командой:
```bash
$ ssh someinternalhost -t "whoami; hostname -f"
astepanenko
someinternalhost.c.infra-188921.internal
```
