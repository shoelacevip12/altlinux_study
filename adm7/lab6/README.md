# Лабораторная работа 6 «`Развертывание PVE и создание PVE-кластера`» 
## Памятка входа
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на реальный хост по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.212 \
"su -"

# вход на виртуальный pve-хост alt-virt11-pve-1 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.208 \
"su -"

# вход на виртуальный pve-хост alt-virt11-pve-2 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.207 \
"su -"

# вход на виртуальный pve-хост alt-virt11-pve-3 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.206 \
"su -"

```
[>>>>>ПОДГОТОВКА ДЛЯ РАБОТЫ с модулем altvirt ADM7<<<<<](../lab6.0/README.md)

![](../lab6.0//img/0.png)

## Выполнение работы
### на стороне Физического
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на виртуальный KVM-хост alt-p11-s1 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.208 \
"su -"

# Установка пакета bridge-utils
apt-get update \
&& apt-get install -y  \
bridge-utils

# Производим базовый вывод информации об ip адресации и интерфейсах
ip -br a

# вывод имеющихся настроек интересующего интерфейса
cat /etc/net/ifaces/enp1s0/*

# Создаем новый интерфейс путем копирования имеющихся настроек рабочего интерфейса
cp -r \
/etc/net/ifaces/{enp1s0,vmbr0}

# Меняем в новом интерфейсе тип интерфейса с ethernet на bridge
sed -i 's/eth/bri/' \
/etc/net/ifaces/vmbr0/options

# Добавляем опцию привязки мостового интерфейса к интерфейсу выхода в сеть
sed -i '/bri/aHOST=enp1s0' \
/etc/net/ifaces/vmbr0/options

# Убираем получения ip по dhcp у интерфейса с сетью 
sed -i "s/dhcp/static/" \
/etc/net/ifaces/enp1s0/options

sed -i "s/static4/static/" \
/etc/net/ifaces/enp1s0/options

# вывод информации об интерфейсе с сетью
cat /etc/net/ifaces/enp1s0/*

# вывод информации о мостовом интерфейсе
cat /etc/net/ifaces/vmbr0/*

# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown enp1s0 \
&& ifup enp1s0 \
&& systemctl restart network

ping ya.ru -c2
```
### на стороне хоста alt-p11-s3
```bash
# Включаем агента в текущей оснастке
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на виртуальный KVM-хост alt-p11-s3 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.207 \
"su -"

# Установка пакета bridge-utils
apt-get update \
&& apt-get install -y  \
bridge-utils

# Производим базовый вывод информации об ip адресации и интерфейсах
ip -br a

# вывод имеющихся настроек интересующего интерфейса
cat /etc/net/ifaces/enp1s0/*

# Создаем новый интерфейс путем копирования имеющихся настроек рабочего интерфейса
cp -r \
/etc/net/ifaces/{enp1s0,vmbr0}

# Меняем в новом интерфейсе тип интерфейса с ethernet на bridge
sed -i 's/eth/bri/' \
/etc/net/ifaces/vmbr0/options

# Добавляем опцию привязки мостового интерфейса к интерфейсу выхода в сеть
sed -i '/bri/aHOST=enp1s0' \
/etc/net/ifaces/vmbr0/options

# Убираем получения ip по dhcp у интерфейса с сетью 
sed -i "s/dhcp/static/" \
/etc/net/ifaces/enp1s0/options

sed -i "s/static4/static/" \
/etc/net/ifaces/enp1s0/options

# вывод информации об интерфейсе с сетью
cat /etc/net/ifaces/enp1s0/*

# вывод информации о мостовом интерфейсе
cat /etc/net/ifaces/vmbr0/*

# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown enp1s0 \
&& ifup enp1s0 \
&& systemctl restart network

ping ya.ru -c2
```
### на стороне хоста alt-p11-s4
```bash
# Включаем агента в текущей оснастке
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на виртуальный KVM-хост alt-p11-s4 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.206 \
"su -"

# Установка пакета bridge-utils
apt-get update \
&& apt-get install -y  \
bridge-utils

# Производим базовый вывод информации об ip адресации и интерфейсах
ip -br a

# вывод имеющихся настроек интересующего интерфейса
cat /etc/net/ifaces/enp1s0/*

# Создаем новый интерфейс путем копирования имеющихся настроек рабочего интерфейса
cp -r \
/etc/net/ifaces/{enp1s0,vmbr0}

# Меняем в новом интерфейсе тип интерфейса с ethernet на bridge
sed -i 's/eth/bri/' \
/etc/net/ifaces/vmbr0/options

# Добавляем опцию привязки мостового интерфейса к интерфейсу выхода в сеть
sed -i '/bri/aHOST=enp1s0' \
/etc/net/ifaces/vmbr0/options

# Убираем получения ip по dhcp у интерфейса с сетью 
sed -i "s/dhcp/static/" \
/etc/net/ifaces/enp1s0/options

sed -i "s/static4/static/" \
/etc/net/ifaces/enp1s0/options

# вывод информации об интерфейсе с сетью
cat /etc/net/ifaces/enp1s0/*

# вывод информации о мостовом интерфейсе
cat /etc/net/ifaces/vmbr0/*

# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown enp1s0 \
&& ifup enp1s0 \
&& systemctl restart network

ping ya.ru -c2
```
```bash
cat /etc/net/ifaces/vmbr0/*
```
```ini
BOOTPROTO=dhcp
TYPE=bri
HOST=enp1s0
SYSTEMD_CONTROLLED=no
DISABLED=no
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
NM_CONTROLLED=no
ONBOOT=yes
```

![](img/1.png)
![](img/2.png)
![](img/3.png)

### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. ../.. \
&& git status

git remote -v

git commit -am 'оформление для ADM7, lab5 bridge_net_upd1' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```