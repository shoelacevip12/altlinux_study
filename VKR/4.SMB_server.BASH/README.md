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
# `SMB.BASH.Replica`
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
# Обновляем систему и Устанавливаем пакеты для SAMBA-DC и DHCP
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
### Проверка связи через локальные DNS
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
pool 192.168.100.1 iburst
server 192.168.100.253
server 192.168.100.252
EOF
```
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
<summary>xxxx</summary>

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

```log
cat /etc/samba/smb.conf
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
mkdir -v /srv/{smb_work,smb_NOTadmins,trash}
```
```log
mkdir: created directory '/srv/smb_work'
mkdir: created directory '/srv/smb_NOTadmins'
mkdir: created directory '/srv/trash'
```
## Для gitflic

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

git commit -am "[upd0]ДЛЯ ВКР SMB служба" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```