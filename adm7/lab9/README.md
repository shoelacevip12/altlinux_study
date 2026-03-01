# Лабораторная работа 9 «`OpenNebula`» 
## Памятка входа
```bash
# Включаем агента в текущей оснастке для подключения к машине libvirt и виртуальной машине с OpenNebula-MS
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_kvm_host \
&& ssh-add ~/.ssh/id_alt-adm7_2026_host_ed25519


# вход на KVM-хост по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_kvm_host \
-o StrictHostKeyChecking=accept-new \
shoel@192.168.89.193 \
"sudo su"

# вход на Виртуальны-хост по ключу по ssh и вход под суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.191 \
"su -"
```
## Подготовка
![](img/0.png)
### Archlinux host libvirt kvm
#### Создание сети моста средствами systemd
```bash
# Включаем агента в текущей оснастке для подключения к KVM хост на archlinux
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_kvm_host

# вход на хост по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_kvm_host \
-o StrictHostKeyChecking=accept-new \
shoel@192.168.89.193 \
"sudo su"

# отключаем и останавливаем NetworkManager и связанные службы
systemctl \
disable --now \
NetworkManager \
NetworkManager-wait-online

# Включение и запуск служб управления сетью systemd
systemctl \
enable --now \
systemd-networkd \
systemd-resolved


# Создание Интерфейс моста как устройства
cat >/etc/systemd/network/15-br0.netdev<<'EOF'
[NetDev]
Name=br0
Kind=bridge
EOF

# Привязка в существующем конфиге физического Ethernet к мосту
cat >/etc/systemd/network/10-eno1.network<<'EOF'
[Match]
Name=eno1

[Network]
Bridge=br0
EOF

# Сеть моста, создаем настройки IP
cat > /etc/systemd/network/15-br0.network <<'EOF'
[Match]
Name=br0

[Network]
DHCP=ipv4
EOF

# Перезапуск сетевой службы
systemctl restart \
systemd-networkd
```
### Развертывание ВМ средствами virt-manager, подключение с удаленного хоста
```bash
# ЗАпуск агента ssh
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_kvm_host

# Подключение на Физический хост
ssh \
-i ~/.ssh/id_kvm_host \
-o StrictHostKeyChecking=accept-new \
shoel@192.168.89.193

# Запуск формирования VM
## 6 GB RAM изолированной памяти
## 4 Виртуальных ядра CPU
## Автоматическое создание дисков системы ВМ, если не существуют:
### в пуле "VMst" размером в 100 GB
## Подключение существующего образа ISO установщика ОС
## Указание типа ОС ВМ "Linux"
## Указание типа дистрибутива "alt.p11"
## Указание возможности и протокола удаленного подключения "spice"
## Указание, вместо стандартного NAT, создание интерфейса моста привязанного к интерфейсу "br0" физического хоста
## Указание, инициализации Виртуальной машины в uefi
sudo virt-install --name alt-p11-ON-ms \
--ram 6144 \
--vcpus=4 \
--disk pool=VMs,size=100,bus=virtio,format=qcow2 \
--cdrom /home/shoel/iso/alt-server-11.0-x86_64.iso \
--os-type=linux \
--os-variant=alt.p11 \
--graphics spice \
--network bridge=br0 \
--boot uefi
```
```
WARNING  --os-type устарел и ничего не делает. Не используйте его.
WARNING  Дисплей не обнаружен. Virt-viewer не будет запущен.
WARNING  Нет консоли для запуска гостевой системы. По умолчанию будет использоваться --wait -1

Запуск установки...
Выделение «alt-p11-ON-ms.qcow2»                                                                  | 100 GB  00:00:03
Создание домена...                                                                               |         00:00:00

Домен ещё работает. Вероятно, выполняется установка.
Ожидание завершения установки.
```
#### Завершение установки средствами virt-manager
```bash
# Установка контекста удаленного доступа, как подключение по умолчанию, для подключения утилитой virsh
export LIBVIRT_DEFAULT_URI=qemu+ssh://shoel@192.168.89.193/system

# Подключение и вы вод рабочего окружения
virsh uri

# Запуск GUI оснастки
virt-manger
```
![](img/1.png)
![](img/2.png)
![](img/3.png)
![](img/4.png)
![](img/5.png)
![](img/6.png)
![](img/7.png)
![](img/8.png)

### Проброс ранее сгенерированного ключа ssh
```bash
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.191
```
```
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/shoel/.ssh/id_alt-adm7_2026_host_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
skvadmin@192.168.89.191's password: 

Number of key(s) added: 1

Now try logging into the machine, with: "ssh -i /home/shoel/.ssh/id_alt-adm7_2026_host_ed25519 -o 'StrictHostKeyChecking=accept-new' 'skvadmin@192.168.89.191'"
and check to make sure that only the key(s) you wanted were added.
```
### Подключение и обновление Установленного узла
```bash
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_kvm_host \
&& ssh-add ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на Виртуальны-хост по ключу по ssh и вход под суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.191 \
"su -"

# Обновление системы
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y
```
### Создание точки восстановления для дальнейшей работы
```bash
# Выключение ВМ
systemctl poweroff

eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_kvm_host \
&& ssh-add ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на KVM-хост по ключу по ssh
ssh -t \
-i ~/.ssh/id_kvm_host \
-o StrictHostKeyChecking=accept-new \
shoel@192.168.89.193

# Вывод списка всех виртуальных машин system контекста libvirt
sudo virsh list --all
```
```
[sudo] пароль для shoel:
 ID   Имя             Состояние
---------------------------------
 -    alt-p11-ON-ms   выключен
```
```bash
# Создание snapshot
sudo virsh snapshot-create-as \
--domain alt-p11-ON-ms \
--name 1 \
--description "lab9" --atomic
```

### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. ../.. \
&& git status

git remote -v

git commit -am 'оформление для ADM7, lab9 opennebula' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```
## Выполнение задания
### Подготовка и Установка сервера управления OpenNebula
#### Установка пакетов
```bash
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_kvm_host \
&& ssh-add ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на KVM-хост по ключу по ssh
ssh -t \
-i ~/.ssh/id_kvm_host \
-o StrictHostKeyChecking=accept-new \
shoel@192.168.89.193

# Вывод списка всех виртуальных машин system контекста libvirt
sudo virsh list --all

# Запуск Виртуальной машины 
sudo virsh start \
--domain alt-p11-ON-ms

# вход на Виртуальны-хост по ключу по ssh и вход под суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.191 \
"su -"

# Установка пакетов для сервера управления OpenNebula
apt-get update \
&& apt-get install -y \
opennebula-server \
opennebula-common \
gem-opennebula-cli \
opennebula-flow \
opennebula-sunstone \
opennebula-gate \
gem-http-cookie \
bridge-utils \
nfs-clients \
mariadb
```
#### Создание мостового интерфейса
```bash
# Производим базовый вывод информации об ip адресации и интерфейсах
ip -br a
```
```
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           UP             192.168.89.191/24 fe80::5054:ff:fe30:695b/64
```
```bash
# вывод имеющихся настроек интересующего интерфейса
cat /etc/net/ifaces/enp1s0/*
```
```
BOOTPROTO=dhcp
TYPE=eth
SYSTEMD_CONTROLLED=no
DISABLED=no
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
NM_CONTROLLED=no
ONBOOT=yes
```
```bash
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
```
```
BOOTPROTO=static
TYPE=eth
SYSTEMD_CONTROLLED=no
DISABLED=no
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=yes
NM_CONTROLLED=no
ONBOOT=yes
```
```bash
# вывод информации о мостовом интерфейсе
cat /etc/net/ifaces/vmbr0/*
```
```
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
```bash
# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown enp1s0 \
&& ifup enp1s0 \
&& systemctl restart network

ping ya.ru -c2
```
```
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=57 time=10.4 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=57 time=10.4 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 10.382/10.409/10.436/0.027 ms
```
#### Работа с пользовательской учетной записью
```bash
# Вывод административной учетной записи OpenNebula с домашним каталогом в /var/lib/one
getent passwd \
oneadmin
```
```
oneadmin:x:9869:9869:Opennebula Daemon User:/var/lib/one:/bin/bash
```
```bash
# Вывод сформированного пароля для административной учетной записи OpenNebula oneadmin
cat /var/lib/one/.one/one_auth
```
```
oneadmin:9c30b60a974a24f5fa06a9daee42af9d
```
```bash
# Изменение пароля oneadmin для возможности входа в ОС как пользователь
passwd oneadmin
```
```
passwd: updating all authentication tokens for user oneadmin.

You can now choose the new password or passphrase.

A valid password should be a mix of upper and lower case letters, digits, and
other characters.  You can use a password containing at least 7 characters
from all of these classes, or a password containing at least 8 characters
from just 3 of these 4 classes.
An upper case letter that begins the password and a digit that ends it do not
count towards the number of character classes used.

A passphrase should be of at least 3 words, 11 to 72 characters long, and
contain enough different characters.

Alternatively, if no one else can see your terminal now, you can pick this as
your password: "Clinch4Mini-Least".

Enter new password: 
Weak password: not enough different characters or classes for this length.
Re-type new password: 
passwd: all authentication tokens updated successfully.
```
#### Подготовка под кластер высокой доступности для снижения простоев основных сервисов OpenNebula
```bash
# Установка MySQL (MariaDB) для хранения конфигурации (на сервере управления): 
systemctl enable --now \
mariadb.service

# Запуск скрипта предварительной установки
mysql_secure_installation
```
```
/usr/bin/mysql_secure_installation: Deprecated program name. It will be removed in a future release, use 'mariadb-secure-installation' instead

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
haven't set the root password yet, you should just press enter here.

Enter current password for root (enter for none): 
OK, successfully used password, moving on...

Setting the root password or using the unix_socket ensures that nobody
can log into the MariaDB root user without the proper authorisation.

Enable unix_socket authentication? [Y/n] Y
Enabled successfully!
Reloading privilege tables..
 ... Success!


You already have your root account protected, so you can safely answer 'n'.

Change the root password? [Y/n] Y
New password: 
Re-enter new password: 
Password updated successfully!
Reloading privilege tables..
 ... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] Y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] n
 ... skipping.

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] Y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] Y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```
```bash
# Вход в БД под пользователем root
mysql -u root
```
```
mysql: Deprecated program name. It will be removed in a future release, use '/usr/bin/mariadb' instead
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 12
Server version: 11.8.6-MariaDB-alt1 (ALT p11)

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> GRANT ALL PRIVILEGES ON opennebula.* TO 'oneadmin' IDENTIFIED BY 'Pa$$w0rD';
Query OK, 0 rows affected (0.012 sec)

MariaDB [(none)]> SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> \q
Bye
```

### Для github и gitflic
```bash
systemctl poweroff

# Создание snapshot
sudo virsh snapshot-create-as \
--domain alt-p11-ON-ms \
--name 2 \
--description "lab9_install" --atomic

git log --oneline

git branch -v

git switch main

git status

git add . .. ../.. \
&& git status

git remote -v

git commit -am 'оформление для ADM7, lab9 opennebula_install' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```

