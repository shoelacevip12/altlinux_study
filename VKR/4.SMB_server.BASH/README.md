# Впускная квалификационная работа
# Проектирование и автоматизация внедрения гибридной сетевой инфраструктуры на базе Ansible в составе домена AD, прокси-сервера SQUID и Динамического DNS

![](..//0.vpn/img/0.png)

#### ПАМЯТКА ВХОДА

```bash
# Включаем агента в текущей оснастке и прописываем в базу агента созданные и переправленные ключи
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn
```

```bash
# вход на bastion хост по ключу по ssh
> ~/.ssh/known_hosts \
&& ssh -t -o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"su -"
```

```bash
# Вход на altsrv1 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.254 \
"su -"
```

```bash
# Вход на altsrv2(AD1) по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.253 \
"su -"
```

```bash
# Вход на altsrv3(AD2) по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.252 \
"su -"
```

```bash
# Вход на altsrv4 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.251 \
"su -"
```

```bash
# Вывод у dhcp сервера об аренде ip на примере у хоста altwks2
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.253 \
'su -c \
"grep -B10 altwks2 \
/var/lib/dhcp/dhcpd/state/dhcpd.leases" | grep lease'
```

# `SMB.BASH`
## Подготовка SMB сервера
### Проброс ключа

```bash
cat ~/.ssh/id_skv_VKR_vpn.pub \
| ssh -J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

<details>
<summary>Успешность проброса</summary>

```log
Warning: Permanently added '192.168.100.13' (ED25519) to the list of known hosts.
sysadmin@192.168.100.13's password: 
```

</details>


```bash
# Включаем агента в текущей оснастке и прописываем в базу агента созданные и переправленные ключи
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn

# Вход на altsrv4
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
"su -"
```

### Смен имени

```bash
hostnamectl \
set-hostname \
altsrv4.den.skv
```

### Устанавливаем имя NIS-домена

```bash
domainname den.skv
```

### Смена статического IP

```bash
# Удаление временных конфигов интерфейса
rm -fv /etc/net/ifaces/ens19/{options~,ipv4route~,ipv4address~}
```

```log
removed '/etc/net/ifaces/ens19/options~'
removed '/etc/net/ifaces/ens19/ipv4address~'
```

```bash
# Смен IP адреса
sed -i 's/.14/.251/' \
/etc/net/ifaces/ens19/ipv4address
```

### Отключение IPV6

```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" \
| tee -a  /etc/sysctl.conf \
&& sysctl -p
```

```log
net.ipv6.conf.all.disable_ipv6 = 1
```

```bash
# Вывод о состоянии настроек ядра с IPV6
sysctl -a \
| grep "disable_ipv6"
```

```log
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.ens19.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```

### Настройка DNS под внутренние сервера DNS

```bash
# nameserver 192.168.100.252\253 уже поднятые основной и дополнительный DNS сервера
# options rotate - попеременное обращение к DNS, а не по списку
cat > /etc/net/ifaces/ens19/resolv.conf<<'EOF'
nameserver 192.168.100.253
nameserver 192.168.100.252
search den.skv
options rotate
EOF
```

### Вывод информации об интерфейсе

```bash
find /etc/net/ifaces/ens19/
```

```log
/etc/net/ifaces/ens19/
/etc/net/ifaces/ens19/ipv4route
/etc/net/ifaces/ens19/options
/etc/net/ifaces/ens19/resolv.conf
/etc/net/ifaces/ens19/ipv4address
```

```bash
cat /etc/net/ifaces/ens19/*
```

<details>
<summary>ВЫВОД ОБЩИХ ПАРАМЕТРОВ интерфейса</summary>

```ini
192.168.100.251/24
default via 192.168.100.1
BOOTPROTO=static
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
nameserver 192.168.100.253
nameserver 192.168.100.252
search den.skv
options rotate
```

</details>

```bash
# Выключение и включения интерфейса с сеть для сброса и перезапуск службы для запуска мостового
ifdown ens19 \
; ifup ens19 \
; systemctl restart network
```

Последовательность Для принудительного закрытия SSH-сессии без ожидания таймаута
1. **Enter**, чтобы убедиться, что курсор не реагирует.
2. Нажать символ **`~`** (тильда).
3. Затем нажмать **`.`** (точка).

```bash
# Вход на altsrv4 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.251 \
"su -"

hostname
```

```log
altsrv4.den.skv
```

```bash
hostname -i
```

```log
192.168.100.251
```

```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```log
PING ya.ru (77.88.44.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.44.242): icmp_seq=1 ttl=53 time=13.2 ms
64 bytes from ya.ru (77.88.44.242): icmp_seq=2 ttl=53 time=13.1 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 13.058/13.147/13.237/0.089 ms
```

</details>

## Установка пакетов SMB сервер

```bash
# Обновляем систему и Устанавливаем пакеты для SMB и chrony
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get -y install \
samba \
samba-common-tools \
samba-client \
task-auth-ad-sssd \
chrony
```

## Ввод в домен
### Проверка настроек DNS

```bash
resolvconf -l
```

<details>
<summary>вывод reolvconf</summary>

```log
# resolv.conf from ens19
nameserver 192.168.100.253
nameserver 192.168.100.252
search den.skv
options rotate
```

</details>

### Настраиваем синхронизацию под сервера времени Домена

```bash
# вывод конфига клиента
cat > /etc/chrony.conf <<'EOF'
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
server 192.168.100.253 iburst
server 192.168.100.252 iburst
# pool 192.168.100.1 iburst
EOF
```

```bash
# Запуск служб NTP
systemctl enable --now \
chronyd.service
```

```log
Executing: /lib/systemd/systemd-sysv-install enable chronyd
```

```bash
# Запуск ручной синхронизации времени
systemctl restart \
chrony-wait.service

# Проверка NTP с новым сервером
chronyc tracking
```

<details>
<summary>Вывод текущего отслеживания времени</summary>

```log
Reference ID    : C0A864FC (altsrv3.den.skv)
Stratum         : 11
Ref time (UTC)  : Mon Apr 06 22:06:39 2026
System time     : 0.000000070 seconds fast of NTP time
Last offset     : -0.000075933 seconds
RMS offset      : 0.000075933 seconds
Frequency       : 18.065 ppm slow
Residual freq   : -0.526 ppm
Skew            : 17.171 ppm
Root delay      : 0.000495138 seconds
Root dispersion : 0.000052771 seconds
Update interval : 1.8 seconds
Leap status     : Normal
[root@altsrv4 ~]# 
```

</details>

```bash
chronyc sources -v
```

<details>
<summary>Состояние синхронизации с источниками</summary>

```log
  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current best, '+' = combined, '-' = not combined,
| /             'x' = may be in error, '~' = too variable, '?' = unusable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^- altsrv2.den.skv              10   6    17    14   +147us[ +147us] +/-  167us
^* altsrv3.den.skv              10   6    17    15  +8746ns[  -67us] +/-  248us
```

</details>

### Ввод в домен через командную строку 

```bash
# altsrv4 имя вводимого хоста
## smaba_u1 имеет права "Domain Admins"
system-auth write ad \
den.skv \
altsrv4 \
DEN \
'smaba_u1' \
'1qaz@WSX'
```

<details>
<summary>Вывод лога ввода в домен</summary>

```log
Using short domain name -- DEN
Joined 'ALTSRV4' to dns domain 'den.skv'
DNS Update for altsrv4.den.skv failed: ERROR_DNS_UPDATE_FAILED
DNS update failed!
```

</details>

### Проверка подсоединенного узла

```bash
net ads testjoin
```

```log
Join is OK
```

```bash
host altsrv4
```

```log
altsrv4.den.skv has address 192.168.100.251
```

```bash
host 192.168.100.251
```

```log
251.100.168.192.in-addr.arpa domain name pointer altsrv4.den.skv.
```

```bash
ls -lhd /etc/krb5*
```

<details>
<summary>Соджержимое каталога с kerberos</summary>

```log
-rw-r--r-- 1 root root     538 Apr  6 15:30 /etc/krb5.conf
drwxr-xr-x 2 root root    4.0K Jun 30  2024 /etc/krb5.conf.d
-rw-r----- 1 root _keytab 1.2K Apr  6 15:30 /etc/krb5.keytab
```

</details>

```bash
# чистка конфига от комментариев
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
/etc/krb5.conf

cat /etc/krb5.conf
```

<details>
<summary>Настройки клиентского kerberos в домене</summary>

```ini
includedir /etc/krb5.conf.d/
[logging]
[libdefaults]
default_realm = DEN.SKV
 dns_lookup_kdc = true
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_ccache_name = KEYRING:persistent:%{uid}
[realms]
[domain_realm]
```

</details>

## Изменение конфига SMB

```bash
# Бэкап имеющихся рабочих настроек
cp -v /etc/samba/smb.conf{,.bak}
```

```log
'/etc/samba/smb.conf' -> '/etc/samba/smb.conf.bak'
```

```bash
# чистка конфига от комментариев
# /^[[:space:]]*#/d - удаляет строки, начинающиеся с #
# /^[[:space:]]*$/d - удаляет пустые строки.
# /^;/d - удаляет строки, начинающиеся с точки с запятой
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
-e '/^;/d' \
/etc/samba/smb.conf
```

```bash
# Удаление в /etc/samba/smb.conf не используемых ресурсов SMB
# Где:
# /\[homes\]/ - находит начало удаления
# ,/0775$ - указывает диапазон до строки, закачивающейся 0775
# /d удалить все строки что совпали по диапазону
sed -i '/\[homes\]/,/0775$/d' \
/etc/samba/smb.conf
```

```bash
# Вывод файла /etc/samba/smb.conf
cat !$
```

<details>
<summary>Конфиг после чистки</summary>

```ini
cat > /etc/samba/smb.conf
[global]
        security = ads
        realm = DEN.SKV
        workgroup = DEN
        netbios name = ALTSRV4
        template shell = /bin/bash
        kerberos method = system keytab
        wins support = no
        winbind use default domain = yes
        winbind enum users = no
        winbind enum groups = no
        template homedir = /home/DEN.SKV/%U
        idmap config * : range = 200000-2000200000
        idmap config * : backend = sss
        machine password timeout = 0
```

</details>

## Подготовка ресурсов для сетевого обмена

```bash
# Создание каталогов для
mkdir -v /srv/{smb_work,smb_NOTadmins,trash,smb_spec_GR1}
```

```log
mkdir: created directory '/srv/smb_work'
mkdir: created directory '/srv/smb_NOTadmins'
mkdir: created directory '/srv/trash'
mkdir: created directory '/srv/smb_spec_GR1'
```

### ВЫставление Владельцев папок и предварительный доступ

```bash
chown -v Administrator:"Domain Users" \
/srv/trash
```

```
changed ownership of '/srv/trash' from root:root to Administrator:Domain Users
```

```bash
# Заранее проставляем права доступа для каталога /srv/trash
chmod -v \
2775 \
/srv/trash
```

```log
mode of '/srv/trash' changed from 0755 (rwxr-xr-x) to 2775 (rwxrwsr-x)
```

```bash
chown -v Administrator:"Domain Admins" \
/srv/smb_NOTadmins
```

```
changed ownership of '/srv/smb_NOTadmins' from root:root to Administrator:Domain Admins
```

```bash
# Заранее проставляем права доступа для каталога /srv/smb_NOTadmins
chmod -v \
2770 \
/srv/smb_NOTadmins
```

```log
mode of '/srv/smb_NOTadmins' changed from 0755 (rwxr-xr-x) to 2770 (rwxrws---)
```

```bash
chown -v Administrator:"Domain Users" \
/srv/smb_work
```

```
changed ownership of '/srv/smb_work' from root:root to Administrator:Domain Users
```

```bash
# Заранее проставляем права доступа для каталога /srv/smb_work
chmod -v \
2770 \
/srv/smb_work
```

```log
mode of '/srv/smb_work' changed from 0755 (rwxr-xr-x) to 2770 (rwxrws---)
```

```bash
chown -v Administrator:'Вымышленные_герои' \
/srv/smb_spec_GR1
```

```
changed ownership of '/srv/smb_spec_GR1' from root:root to Administrator:Вымышленные_герои
```

```bash
# Заранее проставляем права доступа для каталога /srv/smb_spec_GR1
chmod -v \
2770 \
/srv/smb_spec_GR1
```

```log
mode of '/srv/smb_spec_GR1' changed from 0755 (rwxr-xr-x) to 2770 (rwxrws---)
```

```bash
# Вывод выставленных прав доступа на созданные каталоги
ls -lhd /srv/*
```

<details>
<summary>Вывод ls</summary>

```log
drwxr-xr-x 2 root          root              4.0K Dec 12  2023 /srv/public
drwxrwxrwt 2 root          root              4.0K Dec 12  2023 /srv/share
drwxrws--- 2 administrator domain admins     4.0K Apr  6 17:46 /srv/smb_NOTadmins
drwxrws--- 2 administrator вымышленные_герои 4.0K Apr  6 16:58 /srv/smb_spec_GR1
drwxrws--- 2 administrator domain users      4.0K Apr  6 16:14 /srv/smb_work
drwxrwsr-x 2 administrator domain users      4.0K Apr  6 17:44 /srv/trash
```

</details>

### Формируем конфиг сетевых ресурсов

```bash
cat >/etc/samba/usershares.conf<<'EOF'
[trash]
        comment = TyT /7OJLHbIU TRASH
        path = /srv/trash
        writable = yes
        guest ok = no
        read list = +'Domain Users' +'Domain Admins'
        write list = +'Domain Users' +'Domain Admins'
        browseable = yes
        create mask = 2775
        directory mask = 1775
[IT]
        comment = Для администраторов
        path = /srv/smb_NOTadmins
        writable = yes
        guest ok = no
        read list = +'Domain Admins'
        write list = +'Domain Admins'
        browseable = no
        create mask = 2770
        directory mask = 1770
[Work]
        comment = Для работы пользователям домена
        path = /srv/smb_work
        writable = yes
        guest ok = no
        read list = +'Domain Users' +'Domain Admins'
        write list = +'Domain Users' +'Domain Admins'
        browseable = yes
        create mask = 2770
        directory mask = 1770
[VG]
        comment = Для работы специальной группе
        path = /srv/smb_spec_GR1
        writable = yes
        guest ok = no
        read list = +'Вымышленные_герои' +'Domain Admins'
        write list = +'Вымышленные_герои' +'Domain Admins'
        browseable = yes
        create mask = 2770
        directory mask = 1770
EOF
```

```bash
# Добавляем в Общий конфиг /etc/samba/smb.conf обращение к файлу с отдельными прописанными сетевыми ресурсами
echo "        include = /etc/samba/usershares.conf" \
| tee -a /etc/samba/smb.conf
```

```log
        include = /etc/samba/usershares.conf
```

### Проверка настроек /etc/samba/smb.conf

```bash
testparm -s
```

<details>
<summary>Вывод проверок конфига</summary>

```ini
Load smb config files from /etc/samba/smb.conf
Loaded services file OK.
Weak crypto is allowed by GnuTLS (e.g. NTLM as a compatibility fallback)

ERROR: Do not use the 'sss' backend as the default idmap backend!

Server role: ROLE_DOMAIN_MEMBER

# Global parameters
[global]
        kerberos method = system keytab
        machine password timeout = 0
        realm = DEN.SKV
        security = ADS
        template homedir = /home/DEN.SKV/%U
        template shell = /bin/bash
        winbind use default domain = Yes
        workgroup = DEN
        idmap config * : range = 200000-2000200000
        idmap config * : backend = sss
        include = /etc/samba/usershares.conf


[trash]
        comment = TyT /7OJLHbIU TRASH
        create mask = 02774
        directory mask = 01774
        path = /srv/trash
        read list = +'Domain Users' +'Domain Admins'
        read only = No
        write list = +'Domain Users' +'Domain Admins'


[IT]
        browseable = No
        comment = Для администраторов
        create mask = 02770
        directory mask = 01770
        path = /srv/smb_NOTadmins
        read list = +'Domain Admins'
        read only = No
        write list = +'Domain Admins'


[Work]
        comment = Для работы пользователям домена
        create mask = 02770
        directory mask = 01770
        path = /srv/smb_work
        read list = +'Domain Users' +'Domain Admins'
        read only = No
        write list = +'Domain Users' +'Domain Admins'


[VG]
        comment = Для работы специальной группе
        create mask = 02770
        directory mask = 01770
        path = /srv/smb_spec_GR1
        read list = +'Вымышленные_герои' +'Domain Admins'
        read only = No
        write list = +'Вымышленные_герои' +'Domain Admins'
```

</details>

## Запуск службы SMB сервера и службы отображения в сетевом окружении

```bash
systemctl \
enable --now \
smb \
avahi-daemon
```

```log
Synchronizing state of smb.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable smb
Synchronizing state of avahi-daemon.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable avahi-daemon
Created symlink /etc/systemd/system/multi-user.target.wants/smb.service → /lib/systemd/system/smb.service.
```

## Вывод журнала о запуске службы

```bash
journalctl -efu smb
```

<details>
<summary>Первый запуск SMB</summary>

```log
Apr 06 18:05:39 altsrv4.den.skv systemd[1]: Starting Samba SMB Daemon...
Apr 06 18:05:39 altsrv4.den.skv smbd[3422]: [2026/04/06 18:05:39.982609,  0] ../../source3/smbd/server.c:1746(main)
Apr 06 18:05:39 altsrv4.den.skv smbd[3422]:   smbd version 4.19.9-alt9 started.
Apr 06 18:05:39 altsrv4.den.skv smbd[3422]:   Copyright Andrew Tridgell and the Samba Team 1992-2023
Apr 06 18:05:40 altsrv4.den.skv systemd[1]: Started Samba SMB Daemon.

```

</details>

## Проверки доступа к сетевым папкам из-под компьютера в домене

```bash
# Включаем агента в текущей оснастке и прописываем в базу агента созданные и переправленные ключи
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn
```

```bash
# Вход на altwks2 под пользователем с правами 'User Domain'
ssh \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
smaba_u3@192.168.100.50
```

<details>
<summary>Лог Входа</summary>

```log
[shoel@shoellin VKR]$ ssh \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
smaba_u3@192.168.100.50
smaba_u3@192.168.100.50's password: 
Last login: Sat Apr  4 22:55:54 2026 from 192.168.100.1
[smaba_u3@altwks2 ~]$
```

</details>

### Проверка прав в домене

```bash
id
```

<details>
<summary>Вывод прав доступа</summary>

```log
uid=815801105(smaba_u3) gid=815800513(domain users) группы=815800513(domain users),14(uucp),19(proc),22(cdrom),36(vmusers),71(floppy),80(cdwriter),81(audio),83(radio),100(users),450(usershares),471(camera),476(vboxusers),478(fuse),481(video),491(vboxsf),492(vboxadd),498(xgrp),499(scanner),815801106(вымышленные_герои
```

</details>

### Вывод доступных ресурсов для пользователя smaba_u3

```bash
smbclient -L altsrv4 \
-k
```

<details>
<summary>ВЫвод доступных ресурсов для smaba_u3</summary>

```log
WARNING: The option -k|--kerberos is deprecated!

        Sharename       Type      Comment
        ---------       ----      -------
        trash           Disk      TyT /7OJLHbIU TRASH
        Work            Disk      Для работы пользователям домена
        VG              Disk      Для работы специальной группе
        IPC$            IPC       IPC Service (Samba 4.19.9-alt9)
SMB1 disabled -- no workgroup available
```

</details>

### Доступ до неотображаемого ресурса для пользователя smaba_u3

```bash
smbclient //altsrv4/IT \
-k \
-c 'ls'
```

```log
WARNING: The option -k|--kerberos is deprecated!
NT_STATUS_ACCESS_DENIED listing \*
```

### Отображение ресурсов под разными пользователями с пользовательского хоста altwks2

```bash
# Скрипт отображения ресурсов для разных пользователей
for p in {1..3}; do \
echo "=== smbclient smaba_u$p ==="; \
smbclient -L altsrv4 \
-U smaba_u$p \
--password '1qaz@WSX'; done
```

<details>
<summary>Вывод для разных пользователей</summary>

```log
=== smbclient smaba_u1 ===

        Sharename       Type      Comment
        ---------       ----      -------
        trash           Disk      TyT /7OJLHbIU TRASH
        Work            Disk      Для работы пользователям домена
        VG              Disk      Для работы специальной группе
        IPC$            IPC       IPC Service (Samba 4.19.9-alt9)
SMB1 disabled -- no workgroup available
=== smbclient smaba_u2 ===

        Sharename       Type      Comment
        ---------       ----      -------
        trash           Disk      TyT /7OJLHbIU TRASH
        Work            Disk      Для работы пользователям домена
        VG              Disk      Для работы специальной группе
        IPC$            IPC       IPC Service (Samba 4.19.9-alt9)
SMB1 disabled -- no workgroup available
=== smbclient smaba_u3 ===

        Sharename       Type      Comment
        ---------       ----      -------
        trash           Disk      TyT /7OJLHbIU TRASH
        Work            Disk      Для работы пользователям домена
        VG              Disk      Для работы специальной группе
        IPC$            IPC       IPC Service (Samba 4.19.9-alt9)
SMB1 disabled -- no workgroup available
```

</details>

### Попытка входа под разными пользователями на не отображаемый ресурс IT

```bash
# Скрипт входа в каталог IT под разными пользователями
for p in {1..3}; do \
echo "=== smbclient smaba_u$p ==="; \
smbclient //altsrv4/IT \
-U smaba_u$p%1qaz@WSX \
-c 'ls'; \
done
```

<details>
<summary>Вывод скрипта входа на скрытый ресурс</summary>

```log
=== smbclient smaba_u1 ===
  .                                   D        0  Mon Apr  6 17:46:02 2026
  ..                                  D        0  Mon Apr  6 17:46:02 2026

                31856428 blocks of size 1024. 26798496 blocks available
=== smbclient smaba_u2 ===
NT_STATUS_ACCESS_DENIED listing \*
=== smbclient smaba_u3 ===
NT_STATUS_ACCESS_DENIED listing \*
```

</details>


## Для gitflic и github

```bash
git branch -v

git log --oneline

git switch main

git status

pushd \
..

git rm -r --cached \
. ../

git add . ../ \
&& git status

git remote -v

git commit -am "[upd2]ДЛЯ ВКР SMB служба" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```