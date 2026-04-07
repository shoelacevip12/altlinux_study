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
# `SQUID.BASH`
## Подготовка SMB сервера
### Проброс ключа
```bash
cat ~/.ssh/id_skv_VKR_vpn.pub \
| ssh -J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

<details>
<summary>Успешность проброса</summary>

```log
Warning: Permanently added '192.168.100.11' (ED25519) to the list of known hosts.
sysadmin@192.168.100.11's password: 
```

</details>


```bash
# Включаем агента в текущей оснастке и прописываем в базу агента созданные и переправленные ключи
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn

# Вход на altsrv1
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
"su -"
```
### Смен имени
```bash
hostnamectl \
set-hostname \
altsrv1.den.skv
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
removed '/etc/net/ifaces/ens19/ipv4route~'
```
```bash
# Смен IP адреса
sed -i 's/.11/.254/' \
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
192.168.100.254/24
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
# Вход на altsrv1 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.254 \
"su -"

hostname
```
```log
altsrv1.den.skv
```
```bash
hostname -i
```
```log
192.168.100.254
```
```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```log
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=53 time=12.8 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=53 time=13.2 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 12.821/13.006/13.191/0.185 ms
```

</details>

## Установка пакетов SMB сервер
```bash
# Обновляем систему и Устанавливаем пакеты для SMB и chrony
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get -y install \
squid \
squid-helpers \
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
Reference ID    : C0A864FD (altsrv2.den.skv)
Stratum         : 11
Ref time (UTC)  : Mon Apr 06 21:57:15 2026
System time     : 0.000025584 seconds fast of NTP time
Last offset     : +0.000044772 seconds
RMS offset      : 0.000044772 seconds
Frequency       : 18.118 ppm slow
Residual freq   : +0.023 ppm
Skew            : 0.481 ppm
Root delay      : 0.000359400 seconds
Root dispersion : 0.000333967 seconds
Update interval : 64.6 seconds
Leap status     : Normal
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
^* altsrv2.den.skv              10   6   377     0  -6781ns[-8245ns] +/-  517us
^- altsrv3.den.skv              10   6   377    64   -201us[ -204us] +/-  552us
```

</details>


### Ввод в домен через командную строку 
```bash
# altsrv1 имя вводимого хоста
## smaba_u1 имеет права "Domain Admins"
system-auth write ad \
den.skv \
altsrv1 \
DEN \
'smaba_u1' \
'1qaz@WSX'
```

<details>
<summary>Вывод лога ввода в домен</summary>

```log
Using short domain name -- DEN
Joined 'ALTSRV1' to dns domain 'den.skv'
Successfully registered hostname with DNS
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
host altsrv1
```
```log
altsrv1.den.skv has address 192.168.100.254
```
```bash
host 192.168.100.254
```
```log
254.100.168.192.in-addr.arpa domain name pointer altsrv1.den.skv.
```
```bash
ls -lhd /etc/krb5*
```

<details>
<summary>Соджержимое каталога с kerberos</summary>

```log
-rw-r--r-- 1 root root     538 Apr  7 01:10 /etc/krb5.conf
drwxr-xr-x 2 root root    4.0K Jun 30  2024 /etc/krb5.conf.d
-rw-r----- 1 root _keytab 1.2K Apr  7 01:09 /etc/krb5.keytab
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

## Добавление SPN записи kerberos
```bash
net -v ads \
keytab add \
HTTP \
-U smaba_u1
```
```log
Processing principals to add...
Password for [DEN\smaba_u1]:
```
```bash
# Просмотр доступных принципалов
klist -k -e \
/etc/krb5.keytab
```

<details>
<summary>Вывод SPN kerberos</summary>

```log
Keytab name: FILE:/etc/krb5.keytab
KVNO Principal
---- --------------------------------------------------------------------------
   1 host/altsrv1.den.skv@DEN.SKV (aes256-cts-hmac-sha1-96) 
   1 host/ALTSRV1@DEN.SKV (aes256-cts-hmac-sha1-96) 
   1 host/altsrv1.den.skv@DEN.SKV (aes128-cts-hmac-sha1-96) 
   1 host/ALTSRV1@DEN.SKV (aes128-cts-hmac-sha1-96) 
   1 host/altsrv1.den.skv@DEN.SKV (DEPRECATED:arcfour-hmac) 
   1 host/ALTSRV1@DEN.SKV (DEPRECATED:arcfour-hmac) 
   1 restrictedkrbhost/altsrv1.den.skv@DEN.SKV (aes256-cts-hmac-sha1-96) 
   1 restrictedkrbhost/ALTSRV1@DEN.SKV (aes256-cts-hmac-sha1-96) 
   1 restrictedkrbhost/altsrv1.den.skv@DEN.SKV (aes128-cts-hmac-sha1-96) 
   1 restrictedkrbhost/ALTSRV1@DEN.SKV (aes128-cts-hmac-sha1-96) 
   1 restrictedkrbhost/altsrv1.den.skv@DEN.SKV (DEPRECATED:arcfour-hmac) 
   1 restrictedkrbhost/ALTSRV1@DEN.SKV (DEPRECATED:arcfour-hmac) 
   1 ALTSRV1$@DEN.SKV (aes256-cts-hmac-sha1-96) 
   1 ALTSRV1$@DEN.SKV (aes128-cts-hmac-sha1-96) 
   1 ALTSRV1$@DEN.SKV (DEPRECATED:arcfour-hmac) 
   1 HTTP/altsrv1.den.skv@DEN.SKV (aes256-cts-hmac-sha1-96) 
   1 HTTP/ALTSRV1@DEN.SKV (aes256-cts-hmac-sha1-96) 
   1 HTTP/altsrv1.den.skv@DEN.SKV (aes128-cts-hmac-sha1-96) 
   1 HTTP/ALTSRV1@DEN.SKV (aes128-cts-hmac-sha1-96) 
   1 HTTP/altsrv1.den.skv@DEN.SKV (DEPRECATED:arcfour-hmac) 
   1 HTTP/ALTSRV1@DEN.SKV (DEPRECATED:arcfour-hmac)
```

</details>

```bash
# просмотр прав до файла keytab
ls -l /etc/krb5.keytab
```
```log
-rw-r----- 1 root _keytab 1572 Apr  7 01:18 /etc/krb5.keytab
```
```bash
# Предоставление прав доступа к системному файлу keytab
usermod -aG \
_keytab \
squid
```
## Настройка конфигов Squid
```bash
# Бэкап первоначального конфига
cp -v /etc/squid/squid.conf{,.bak}
```
```log
'/etc/squid/squid.conf' -> '/etc/squid/squid.conf.bak'
```

## Для gitflic и github
```bash
git remote -v
```
```log
altlinux        https://github.com/shoelacevip12/altlinux_study.git (fetch)
altlinux        https://github.com/shoelacevip12/altlinux_study.git (push)
altlinux_gf     https://gitflic.ru/project/shoelacevip12/altlinux_study.git (fetch)
altlinux_gf     https://gitflic.ru/project/shoelacevip12/altlinux_study.git (push)
```
```bash
git remote rm \
altlinux

git remote rm \
altlinux_gf
```
```bash
# Добавление источника для авторизации на gitflic по ssh
git remote add \
altlinux_gf \
git@gitflic.ru:shoelacevip12/altlinux_study.git


# Добавление источника для авторизации на github по ssh
git remote add \
altlinux \
git@github.com:shoelacevip12/altlinux_study.git
```
```bash
git remote -v
```
```log
altlinux        git@github.com:shoelacevip12/altlinux_study.git (fetch)
altlinux        git@github.com:shoelacevip12/altlinux_study.git (push)
altlinux_gf     git@gitflic.ru:shoelacevip12/altlinux_study.git (fetch)
altlinux_gf     git@gitflic.ru:shoelacevip12/altlinux_study.git (push
```
```bash
# Добавляем ключи агенту ssh от репозитория gitflic и github
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_gitflic_2026_ed25519 \
&& ssh-add ~/.ssh/id_github_2026_ed25519 \
&& ssh-agent -c

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

git commit -am "[upd0]ДЛЯ ВКР SQUID служба" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```