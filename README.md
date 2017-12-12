## Otus DevOps HW 5 by Aleksey Stepanenko

### Описание

Хост bastion, IP: 35.198.128.243, внутр. IP: 10.156.0.2
Хост: someinternalhost, внутр. IP: 10.156.0.3

### ДЗ со слайда 36

Самостоятельное задание
Исследовать способ подключения к internalhost в одну команду из вашего рабочего устройства,
проверить работоспособность найденного решения и внести его в README.md в вашем репозитории

Вариант 1:
```bash
ssh -J astepanenko@35.198.128.243 astepanenko@10.156.0.3
```
```bash
$ $ ssh -J 35.198.128.243 10.156.0.3 -t "whoami; hostname"
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
```buildoutcfg
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

