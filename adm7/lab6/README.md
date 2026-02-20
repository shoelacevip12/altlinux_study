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
### Со стороны первого узла alt-virt11-pve-1.lab
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на виртуальный PVE-хост alt-virt11-pve-1 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.208 \
"su -"

# Обновление узла
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y

# Убираем из myhostname для отработки файла /etc/hosts в 11 платформе
sed -i 's/files myhostname dns/files dns/' \
/etc/nsswitch.conf
```
```
passwd:     files systemd
shadow:     tcb files
group:      files systemd
gshadow:    files


hosts:      files dns


ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files


automount:  files
aliases:    files
```
```bash
# Производим базовый вывод информации об ip адресации и интерфейсах
ip -br a

# к дополнительному интерфейсу, присваиваем ipv6 адрес
```
```
auto lo
iface lo inet loopback

iface ens19 inet manual

auto ens20
iface ens20 inet6 static
        address fdd2:3918:5fad::1/126

auto vmbr0
iface vmbr0 inet static
        address 192.168.89.208/24
        gateway 192.168.89.1
        bridge-ports ens19
        bridge-stp off
        bridge-fd 0
        dns-nameservers 192.168.89.1
        dns-search lab

source /etc/network/interfaces.d/*
```
![](img/1.png)

```bash
# Изменение локального файла разрешения имен
# Добавляем себя из-за удаления myhostname в /etc/nsswitch.conf
cat > /etc/hosts <<'EOF'
::1             localhost ip6-localhost ip6-loopback
fdd2:3918:5fad::1 alt-virt11-pve-1.lab alt-virt11-pve-1
fdd2:3918:5fad::2 alt-virt11-pve-2.lab alt-virt11-pve-2
fdd2:3918:5fad::3 alt-virt11-pve-3.lab alt-virt11-pve-3

127.0.0.1       localhost.localdomain localhost
192.168.89.208 alt-virt11-pve-1.lab alt-virt11-pve-1
EOF

ping -c2 \
alt-virt11-pve-2.lab

ping -c2 \
alt-virt11-pve-3.lab
```
#### Формирование уникальной пары ключей для соседних хостов
```bash
# Формирование уникальной пары ключей для соседних хостов
ssh-keygen \
-f ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519 \
-t ed25519 \
-C "fr_pve1_to_pve2"

ssh-keygen \
-f ~/.ssh/id_alt-adm7_pve1-to-pve3_ed25519 \
-t ed25519 \
-C "fr_pve1_to_pve3"

# назначение правильных прав на пары ключей
chmod 600 \
~/.ssh/id_alt-adm7_*_ed25519

chmod 644 \
~/.ssh/id_alt-adm7_*_ed25519.pub
```
#### проброс ключей
##### до узла alt-virt11-pve-2.lab
```bash
# на узел alt-virt11-pve-2.lab сначала до ПОЛЬЗОВАТЕЛЕЙ с правами wheel
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519.pub \
skvadmin@alt-virt11-pve-2.lab

# Вход на пользователя с возможностью перехода в суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519 \
skvadmin@alt-virt11-pve-2.lab \
"su -"

# Перенос проброшенного на пользователя с PVE1 публичного ключа на суперпользователя к подключенному хосту
grep fr_pve1 \
/home/skvadmin/.ssh/authorized_keys \
>> .ssh/authorized_keys

# проверка наличия
cat .ssh/authorized_keys

# Возращение на PV1
exit
```
```bash
# Проверка Входа на суперпользователя удаленного хоста напрямую
ssh -o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519 \
root@alt-virt11-pve-2.lab

exit
```
##### до узла alt-virt11-pve-3.lab
```bash
# на узел alt-virt11-pve-3.lab сначала до ПОЛЬЗОВАТЕЛЕЙ с правами wheel
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve3_ed25519.pub \
skvadmin@alt-virt11-pve-3.lab

# Вход на пользователя с возможностью перехода в суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve3_ed25519 \
skvadmin@alt-virt11-pve-3.lab \
"su -"

# Перенос проброшенного на пользователя с PVE1 публичного ключа на суперпользователя к подключенному хосту
grep fr_pve1 \
/home/skvadmin/.ssh/authorized_keys \
>> .ssh/authorized_keys

# проверка наличия нужного ключа
cat .ssh/authorized_keys

# Возращение на PVE1
exit
```
```bash
# Проверка Входа на суперпользователя удаленного хоста напрямую
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve3_ed25519 \
root@alt-virt11-pve-3.lab \
hostname -s
```
#### Настройка сервера времени
```bash
# Бэкап конфигурации
cp /etc/chrony.conf{,.bak}

# чистка конфига от комментариев
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
/etc/chrony.conf

# Перенастраиваем основной сервер на Московские серверы ВНИИФТРИ ntp3.vniiftri.ru
sed -i 's/pool pool.ntp.org/server ntp3.vniiftri.ru/' \
/etc/chrony.conf

# Добавляем как дополнительный сервер участника кластера PVE alt-virt11-pve-2
sed -i  '/iburst/aserver alt-virt11-pve-2.lab iburst' \
/etc/chrony.conf

# Добавляем как дополнительный сервер участника кластера PVE alt-virt11-pve-3
sed -i '/lab iburst/aserver alt-virt11-pve-3.lab iburst' \
/etc/chrony.conf

# Указание что хост выступает в роли сервера времени для сети fdd2:3918:5fad::/126
sed -i '/rtcsync/aallow fdd2:3918:5fad::/126' \
/etc/chrony.conf

# Указываем возможность отвечать клиентам, если к внешнему NTP серверу нет доступа
sed -i '/\/126/alocal stratum 10' \
/etc/chrony.conf

# Перезапуск служб NTP
systemctl restart \
chrony-wait.service \
chronyd.service \
chrony.service

# Проверка NTP с новым сервером
chronyc tracking
chronyc sources -v

# Проверка открытого порта для клиентов
ss -ulnp | grep :123
```
```
server ntp3.vniiftri.ru iburst
server alt-virt11-pve-2.lab iburst
server alt-virt11-pve-3.lab iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow fdd2:3918:5fad::/126
local stratum 10
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
```

### Со стороны первого узла alt-virt11-pve-2.lab
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на виртуальный PVE-хост alt-virt11-pve-2 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.207 \
"su -"

# Обновление узла
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y

# Убираем из myhostname для отработки файла /etc/hosts в 11 платформе
sed -i 's/files myhostname dns/files dns/' \
/etc/nsswitch.conf
```
```
passwd:     files systemd
shadow:     tcb files
group:      files systemd
gshadow:    files

hosts:      files dns

ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files

automount:  files
aliases:    files
```
```bash
# Производим базовый вывод информации об ip адресации и интерфейсах
ip -br a

# к дополнительному интерфейсу, присваиваем ipv6 адрес
```
```
auto lo
iface lo inet loopback

iface ens19 inet manual

auto ens20
iface ens20 inet6 static
        address fdd2:3918:5fad::2/126

auto vmbr0
iface vmbr0 inet static
        address 192.168.89.207/24
        gateway 192.168.89.1
        bridge-ports ens19
        bridge-stp off
        bridge-fd 0
        dns-nameservers 192.168.89.1
        dns-search lab

source /etc/network/interfaces.d/*
```
![](img/2.png)

```bash
# Изменение локального файла разрешения имен
# Добавляем себя из-за удаления myhostname в /etc/nsswitch.conf
cat > /etc/hosts <<'EOF'
::1             localhost ip6-localhost ip6-loopback
fdd2:3918:5fad::1 alt-virt11-pve-1.lab alt-virt11-pve-1
fdd2:3918:5fad::2 alt-virt11-pve-2.lab alt-virt11-pve-2
fdd2:3918:5fad::3 alt-virt11-pve-3.lab alt-virt11-pve-3

127.0.0.1       localhost.localdomain localhost
192.168.89.207 alt-virt11-pve-2.lab alt-virt11-pve-2
EOF

ping -c2 \
alt-virt11-pve-1.lab

ping -c2 \
alt-virt11-pve-3.lab
```
#### Формирование уникальной пары ключей для соседних хостов
```bash
# Формирование уникальной пары ключей для соседних хостов
ssh-keygen \
-f ~/.ssh/id_alt-adm7_pve2-to-pve1_ed25519 \
-t ed25519 \
-C "fr_pve2_to_pve1"

ssh-keygen \
-f ~/.ssh/id_alt-adm7_pve2-to-pve3_ed25519 \
-t ed25519 \
-C "fr_pve2_to_pve3"

# назначение правильных прав на пары ключей
chmod 600 \
~/.ssh/id_alt-adm7_*_ed25519

chmod 644 \
~/.ssh/id_alt-adm7_*_ed25519.pub
```
#### проброс ключей
##### до узла alt-virt11-pve-1.lab
```bash
# на узел alt-virt11-pve-1.lab сначала до ПОЛЬЗОВАТЕЛЕЙ с правами wheel
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve2-to-pve1_ed25519.pub \
skvadmin@alt-virt11-pve-1.lab

# Вход на пользователя с возможностью перехода в суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve2-to-pve1_ed25519 \
skvadmin@alt-virt11-pve-1.lab \
"su -"

# Перенос проброшенного на пользователя с PVE2 публичного ключа на суперпользователя к подключенному хосту
grep fr_pve2 \
/home/skvadmin/.ssh/authorized_keys \
>> .ssh/authorized_keys

# проверка наличия
grep fr_pve2 \
.ssh/authorized_keys

# Возращение на PVE2
exit
```
```bash
# Проверка Входа на суперпользователя удаленного хоста напрямую
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve2-to-pve1_ed25519 \
root@alt-virt11-pve-1.lab \
hostname -s
```
##### до узла alt-virt11-pve-3.lab
```bash
# на узел alt-virt11-pve-3.lab сначала до ПОЛЬЗОВАТЕЛЕЙ с правами wheel
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve2-to-pve3_ed25519.pub \
skvadmin@alt-virt11-pve-3.lab

# Вход на пользователя с возможностью перехода в суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve2-to-pve3_ed25519 \
skvadmin@alt-virt11-pve-3.lab \
"su -"

# Перенос проброшенного на пользователя с PVE2 публичного ключа на суперпользователя к подключенному хосту
grep fr_pve2 \
/home/skvadmin/.ssh/authorized_keys \
>> .ssh/authorized_keys

# проверка наличия нужного ключа
grep fr_pve2 \
.ssh/authorized_keys

# Возращение на PVE2
exit
```
```bash
# Проверка Входа на суперпользователя удаленного хоста напрямую
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve2-to-pve3_ed25519 \
root@alt-virt11-pve-3.lab \
hostname -s
```
#### Настройка сервера времени
```bash
# Бэкап конфигурации
cp /etc/chrony.conf{,.bak}

# чистка конфига от комментариев
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
/etc/chrony.conf

# Перенастраиваем основной сервер на Московские серверы ВНИИФТРИ ntp3.vniiftri.ru
sed -i 's/pool pool.ntp.org/server ntp3.vniiftri.ru/' \
/etc/chrony.conf

# Добавляем как дополнительный сервер участника кластера PVE alt-virt11-pve-1
sed -i  '/iburst/aserver alt-virt11-pve-1.lab iburst' \
/etc/chrony.conf

# Добавляем как дополнительный сервер участника кластера PVE alt-virt11-pve-3
sed -i '/lab iburst/aserver alt-virt11-pve-3.lab iburst' \
/etc/chrony.conf

# Указание что хост выступает в роли сервера времени для сети fdd2:3918:5fad::/126
sed -i '/rtcsync/aallow fdd2:3918:5fad::/126' \
/etc/chrony.conf

# Указываем возможность отвечать клиентам, если к внешнему NTP серверу нет доступа
sed -i '/\/126/alocal stratum 10' \
/etc/chrony.conf

# Перезапуск служб NTP
systemctl restart \
chrony-wait.service \
chronyd.service \
chrony.service

# Проверка NTP с новым сервером
chronyc tracking
chronyc sources -v

# Проверка открытого порта для клиентов
ss -ulnp | grep :123
```
```
server ntp3.vniiftri.ru iburst
server alt-virt11-pve-1.lab iburst
server alt-virt11-pve-3.lab iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow fdd2:3918:5fad::/126
local stratum 10
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
```


### Со стороны первого узла alt-virt11-pve-3.lab
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на виртуальный PVE-хост alt-virt11-pve-3 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.206 \
"su -"

# Обновление узла
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y

# Убираем из myhostname для отработки файла /etc/hosts в 11 платформе
sed -i 's/files myhostname dns/files dns/' \
/etc/nsswitch.conf
```
```
passwd:     files systemd
shadow:     tcb files
group:      files systemd
gshadow:    files

# hosts:      files myhostname dns
hosts:      files dns

ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files

automount:  files
aliases:    files
```
```bash
# Производим базовый вывод информации об ip адресации и интерфейсах
ip -br a

# к дополнительному интерфейсу, присваиваем ipv6 адрес
```
```
auto lo
iface lo inet loopback

iface ens19 inet manual

auto ens20
iface ens20 inet6 static
        address fdd2:3918:5fad::3/126

auto vmbr0
iface vmbr0 inet static
        address 192.168.89.206/24
        gateway 192.168.89.1
        bridge-ports ens19
        bridge-stp off
        bridge-fd 0
        dns-nameservers 192.168.89.1
        dns-search lab

source /etc/network/interfaces.d/*
```
![](img/3.png)

```bash
# Изменение локального файла разрешения имен
# Добавляем себя из-за удаления myhostname в /etc/nsswitch.conf
cat > /etc/hosts <<'EOF'
::1             localhost ip6-localhost ip6-loopback
fdd2:3918:5fad::1 alt-virt11-pve-1.lab alt-virt11-pve-1
fdd2:3918:5fad::2 alt-virt11-pve-2.lab alt-virt11-pve-2
fdd2:3918:5fad::3 alt-virt11-pve-3.lab alt-virt11-pve-3
fdd2:3918:5fad:: alt-virt11-pve-4.lab alt-virt11-pve-4

127.0.0.1       localhost.localdomain localhost
192.168.89.206 alt-virt11-pve-3.lab alt-virt11-pve-3
EOF

ping -c2 \
alt-virt11-pve-1.lab

ping -c2 \
alt-virt11-pve-2.lab
```
#### Формирование уникальной пары ключей для соседних хостов
```bash
# Формирование уникальной пары ключей для соседних хостов
ssh-keygen \
-f ~/.ssh/id_alt-adm7_pve3-to-pve1_ed25519 \
-t ed25519 \
-C "fr_pve3_to_pve1"

ssh-keygen \
-f ~/.ssh/id_alt-adm7_pve3-to-pve2_ed25519 \
-t ed25519 \
-C "fr_pve3_to_pve2"

# назначение правильных прав на пары ключей
chmod 600 \
~/.ssh/id_alt-adm7_*_ed25519

chmod 644 \
~/.ssh/id_alt-adm7_*_ed25519.pub
```
#### проброс ключей
##### до узла alt-virt11-pve-1.lab
```bash
# на узел alt-virt11-pve-1.lab сначала до ПОЛЬЗОВАТЕЛЕЙ с правами wheel
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve3-to-pve1_ed25519.pub \
skvadmin@alt-virt11-pve-1.lab

# Вход на пользователя с возможностью перехода в суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve3-to-pve1_ed25519 \
skvadmin@alt-virt11-pve-1.lab \
"su -"

# Перенос проброшенного на пользователя с PVE3 публичного ключа на суперпользователя к подключенному хосту
grep fr_pve3 \
/home/skvadmin/.ssh/authorized_keys \
>> .ssh/authorized_keys

# проверка наличия
grep fr_pve3 \
.ssh/authorized_keys

# Возращение на PVE3
exit
```
```bash
# Проверка Входа на суперпользователя удаленного хоста напрямую
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve3-to-pve1_ed25519 \
root@alt-virt11-pve-1.lab \
hostname -s
```
##### до узла alt-virt11-pve-2.lab
```bash
# на узел alt-virt11-pve-2.lab сначала до ПОЛЬЗОВАТЕЛЕЙ с правами wheel
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve3-to-pve2_ed25519.pub \
skvadmin@alt-virt11-pve-2.lab

# Вход на пользователя с возможностью перехода в суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve3-to-pve2_ed25519 \
skvadmin@alt-virt11-pve-2.lab \
"su -"

# Перенос проброшенного на пользователя с PVE3 публичного ключа на суперпользователя к подключенному хосту
grep fr_pve3 \
/home/skvadmin/.ssh/authorized_keys \
>> .ssh/authorized_keys

# проверка наличия нужного ключа
grep fr_pve3 \
.ssh/authorized_keys

# Возращение на PVE3
exit
```
```bash
# Проверка Входа на суперпользователя удаленного хоста напрямую
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve3-to-pve2_ed25519 \
root@alt-virt11-pve-2.lab \
hostname -s
```
#### Настройка сервера времени
```bash
# Бэкап конфигурации
cp /etc/chrony.conf{,.bak}

# чистка конфига от комментариев
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
/etc/chrony.conf

# Перенастраиваем основной сервер на Московские серверы ВНИИФТРИ ntp3.vniiftri.ru
sed -i 's/pool pool.ntp.org/server ntp3.vniiftri.ru/' \
/etc/chrony.conf

# Добавляем как дополнительный сервер участника кластера PVE alt-virt11-pve-1
sed -i  '/iburst/aserver alt-virt11-pve-1.lab iburst' \
/etc/chrony.conf

# Добавляем как дополнительный сервер участника кластера PVE alt-virt11-pve-2
sed -i '/lab iburst/aserver alt-virt11-pve-2.lab iburst' \
/etc/chrony.conf

# Указание что хост выступает в роли сервера времени для сети fdd2:3918:5fad::/126
sed -i '/rtcsync/aallow fdd2:3918:5fad::/126' \
/etc/chrony.conf

# Указываем возможность отвечать клиентам, если к внешнему NTP серверу нет доступа
sed -i '/\/126/alocal stratum 10' \
/etc/chrony.conf

# Перезапуск служб NTP
systemctl restart \
chrony-wait.service \
chronyd.service \
chrony.service

# Проверка NTP с новым сервером
chronyc tracking
chronyc sources -v

# Проверка открытого порта для клиентов
ss -ulnp | grep :123
```
```
server ntp3.vniiftri.ru iburst
server alt-virt11-pve-1.lab iburst
server alt-virt11-pve-2.lab iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow fdd2:3918:5fad::/126
local stratum 10
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
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

git commit -am 'оформление для ADM7, lab6 prox_clus upd3' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```