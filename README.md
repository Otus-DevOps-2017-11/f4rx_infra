# Aleksey Stepanenko

# HW 7

## ДЗ 1
Сборка образа packer'ом (тут и далее в директории packer)
```bash
packer build \
-var 'proj_id=infra-188921' \
-var 'source_image_family=ubuntu-1604-lts' \
-var 'machine_type=f1-micro' ubuntu16.json
```
или использовать переменные из файла variables.json (за основу взять variables.json.example, указав proj_id)
```bash
packer build -var-file=variables.json ubuntu16.json
```

## ДЗ *
В данном ДЗ я так же поставил перед собой цель собирать образ не на основе Ubuntu, а на основе 
reddit-base подготовленного в первом ДЗ. Поэтому у меня жестко забит в json **"source_image_family":"reddit-base"**  
Опять же так было проще для дебага.  

Запуск приложения сделан через unit-файл из под пользователя puma (см. puma.service) 
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
