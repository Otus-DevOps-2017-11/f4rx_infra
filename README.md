# Aleksey Stepanenko
Table of Contents
=================

   * [Aleksey Stepanenko](#aleksey-stepanenko)
   * [Table of Contents](#table-of-contents)
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


# HW 9 Terraform-2

В данном задание ВМ была разбита на две (по функциональности), ВМ вынесены в модули и созданы два окружения.  
**Замечание.** stage и prod окружения не будут работать вместе из-за одинаковыех названий ВМ и правил FW. Решеним для меня было бы
разнести их по разным Проектам в GCP  
Создан **storage-bucket.tf** управление бакитами (google storage) через терраформ путем инсталяции стороннего модуля.

Используемые команды:
```bash
# установка модулей
terraform get
# установка плагинов
terragorm init
```


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
