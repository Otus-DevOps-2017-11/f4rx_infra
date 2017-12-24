# Aleksey Stepanenko
# HW 8

Использую f1-micro вместо g1-small

Все команды выполняются в директории _terraform_

> 2. Определите input переменную для задания версии провайдера "google"; 

**О.** Вопрос с подвохом, из документации:
>Interpolation is supported only for the per-provider configuration arguments. It is not supported for the special alias and version arguments.





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
