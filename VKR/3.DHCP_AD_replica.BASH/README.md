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
# `AD.BASH.Replica`

## Доступ до altsrv3 сервера ssh
### Проброс имеющегося ключа
```bash
cat ~/.ssh/id_skv_VKR_vpn.pub \
| ssh -J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.13 \
'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

<details>
<summary>Успешность проброса</summary>

```log
Warning: Permanently added '192.168.100.13' (ED25519) to the list of known hosts.
sysadmin@192.168.100.13's password: 
```

</details>

## Смена имени хоста
```bash
# Вход на altsrv3
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.13 \
"su -"

# Удаление временных конфигов интерфейса
rm -fv /etc/net/ifaces/ens19/{options~,ipv4route~}
```
```log
removed '/etc/net/ifaces/ens19/options~'
```
```bash
hostnamectl \
set-hostname \
altsrv3.den.skv
```
## Устанавливаем имя NIS-домена
```bash
domainname den.skv
```
## Смена статического IP
```bash
# Смен IP адреса
sed -i 's/.13/.252/' \
/etc/net/ifaces/ens19/ipv4address

# Смена домена поиска и серверов домен контроллера
# nameserver 192.168.100.253 уже поднятый основной сервер
cat > /etc/net/ifaces/ens19/resolv.conf<<'EOF'
nameserver 192.168.100.253
nameserver 77.88.8.8
search den.skv
EOF
```
## Вывод информации об интерфейсе
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
192.168.100.252/24
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
nameserver 77.88.8.8
search den.skv
```

</details>

```bash
# Отключение IPV6
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
```bash
# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown ens19 \
; ifup ens19 \
; systemctl restart network
```

Последовательность Для принудительного закрытия SSH-сессии без ожидания таймаута
1. **Enter**, чтобы убедиться, что курсор не реагирует.
2. Нажать символ **`~`** (тильда).
3. Затем нажмать **`.`** (точка).

```bash

# Вход на altsrv3 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.252 \
"su -"

hostname
```
```log
altsrv3.den.skv
```
```bash
hostname -i
```
```log
192.168.100.252
```
```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```log
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=53 time=13.1 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=53 time=13.3 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 13.077/13.168/13.260/0.091 ms
```

</details>


## Подготовка и Установка необходимых пакетов для SAMBA-DC
```bash
# Если присутствую останавливаем конфликтующие службы
systemctl stop \
smb \
nmb \
krb5kdc \
slapd \
bind \
dnsmasq

# Обновляем систему и Устанавливаем пакеты для SAMBA-DC и DHCP
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get -y install \
alterator-net-domain \
task-samba-dc \
alterator-datetime \
chrony \
dhcp-server

# Чистка получившихся настроек SAMBA после установки
rm -fv /etc/samba/smb.conf \
&& rm -rfv /var/{lib,cache}/samba
```

<details>
<summary>ВЫВОД чистки</summary>

```log
removed '/etc/samba/smb.conf'
removed directory '/var/lib/samba/winbindd_privileged'
removed directory '/var/lib/samba/sysvol'
removed directory '/var/lib/samba/private'
removed directory '/var/lib/samba'
removed directory '/var/cache/samba'
```

</details>

```bash
# создание каталога для работы Домена
mkdir -pv \
/var/lib/samba/sysvol
```
```log
mkdir: created directory '/var/lib/samba'
mkdir: created directory '/var/lib/samba/sysvol'
```

## Настройка сервера времени Со стороны ВТОРИЧНОГО домен контроллера
```bash
# Бэкап конфигурации
cp /etc/chrony.conf{,.bak}

# чистка конфига от комментариев
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
/etc/chrony.conf

# Перенастраиваем основной сервер на первый домен контроллер
sed -i 's/pool pool.ntp.org/server altsrv2.den.skv/' \
/etc/chrony.conf

# Добавляем как дополнительный сервер Московские серверы ВНИИФТРИ ntp3.vniiftri.ru
sed -i  '/iburst/aserver ntp3.vniiftri.ru iburst' \
/etc/chrony.conf

# Указание что хост выступает в роли сервера времени для всей сети локальной сети 192.168.100.0/24
sed -i '/rtcsync/aallow 192.168.100.0\/24' \
/etc/chrony.conf

# Указываем возможность отвечать клиентам, если к внешнему NTP серверу нет доступа
sed -i '/\/24/alocal stratum 10' \
/etc/chrony.conf

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
Stratum         : 3
Ref time (UTC)  : Sat Apr 04 18:43:17 2026
System time     : 0.000008979 seconds fast of NTP time
Last offset     : +0.000009409 seconds
RMS offset      : 0.000009409 seconds
Frequency       : 18.980 ppm slow
Residual freq   : -0.000 ppm
Skew            : 228.853 ppm
Root delay      : 0.014229921 seconds
Root dispersion : 0.000922328 seconds
Update interval : 2.0 seconds
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
^* altsrv2.den.skv               2   6    17    28    -91us[  -81us] +/- 7391us
^+ ntp3.vniiftri.ru              1   6    17    28    +88us[  +98us] +/- 6958us
```

</details>

```bash
# Проверка открытого порта для клиентов
ss -ulnp | grep :123
```
```log
UNCONN 0      0            0.0.0.0:123       0.0.0.0:*    users:(("chronyd",pid=4183,fd=7))
```
```bash
# настройки NTP на вычислительном узле 
cat /etc/chrony.conf
```
```log
server altsrv2.den.skv iburst
server ntp3.vniiftri.ru iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.100.0/24
local stratum 10
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
```

## Подготовка Kerberos
```bash
# Бэкап конфигурации
cp /etc/krb5.conf{,.bak}

# Подготовка kerberos под необходимые параметры
sed -i 's/lm = true/lm = false/' \
/etc/krb5.conf

sed -i 's/# default_realm = EXAMPLE.COM/\ default_realm = DEN.SKV/' \
/etc/krb5.conf

# чистка конфига от комментариев
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
/etc/krb5.conf
```
```bash
# Вывод получившегося конфига
cat !$
```
```log
cat /etc/krb5.conf
includedir /etc/krb5.conf.d/
[logging]
[libdefaults]
 dns_lookup_kdc = true
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = DEN.SKV
 default_ccache_name = KEYRING:persistent:%{uid}
[realms]
[domain_realm]
```
## последние Проверки готовности
```bash
resolvconf -l
```
```log
# resolv.conf from ens19
nameserver 192.168.100.253
nameserver 77.88.8.8
search den.skv
```

## Создание основного домен контроллера с командной строки
```bash
# Получаем kerberos билет на имя входящего в доменную группу Domain Admins 
kinit -V smaba_u1
```
```log
Using default cache: persistent:0:0
Using principal: smaba_u1@DEN.SKV
Password for smaba_u1@DEN.SKV: 
Authenticated to Kerberos v5
```
```bash
# проверка полученного билета
klist
```

<details>
<summary>ВЫВОД полученного билета</summary>

```log
Ticket cache: KEYRING:persistent:0:0
Default principal: smaba_u1@DEN.SKV

Valid starting     Expires            Service principal
04/04/26 21:45:37  04/05/26 07:45:37  krbtgt/DEN.SKV@DEN.SKV
        renew until 04/11/26 21:45:33
```

</details>

```bash
# Запускать предварительно получив kerberos ключ (проверить командой - klist, получить - командой kinit -V smaba_u1)
# – DC роль участия в домене 
# – -Usmaba_u1 Пользовательская УЗ в группе AD 'Domain Admins'
# – --realm=den.skv как зарегистрировать realm в /etc/samba/smb.conf
# – Все Параметры --option="" для /etc/samba/smb.conf сопоставимые у основного samba DC
samba-tool domain join \
den.skv \
DC \
-Usmaba_u1 \
--realm=den.skv \
--option="dns forwarder=77.88.8.8" \
--option='idmap_ldb:use rfc2307 = yes' \
--option="interfaces= lo ens19" \
--option="bind interfaces only=yes" \
--option="dns zone scavenging=yes" \
--option="allow dns updates=secure only"
```

<details>
<summary>ВЫВОД РАЗВЕРТЫВАНИЯ Вторичного ДОМЕН-КОНТРОЛЕРА</summary>

```log
INFO 2026-04-04 21:48:13,827 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #106: Finding a writeable DC for domain 'den.skv'
INFO 2026-04-04 21:48:13,848 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #108: Found DC altsrv2.den.skv
Password for [WORKGROUP\smaba_u1]:
INFO 2026-04-04 21:48:19,373 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #360: Reconnecting to naming master efd4f526-cd73-4346-acd0-11c841e95d30._msdcs.den.skv
INFO 2026-04-04 21:48:19,477 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #367: DNS name of new naming master is altsrv2.den.skv
INFO 2026-04-04 21:48:19,478 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1649: workgroup is DEN
INFO 2026-04-04 21:48:19,479 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1652: realm is den.skv
Adding CN=ALTSRV3,OU=Domain Controllers,DC=den,DC=skv
Adding CN=ALTSRV3,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=den,DC=skv
Adding CN=NTDS Settings,CN=ALTSRV3,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=den,DC=skv
Adding SPNs to CN=ALTSRV3,OU=Domain Controllers,DC=den,DC=skv
Setting account password for ALTSRV3$
Enabling account
Calling bare provision
INFO 2026-04-04 21:48:20,582 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2128: Looking up IPv4 addresses
INFO 2026-04-04 21:48:20,583 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2145: Looking up IPv6 addresses
WARNING 2026-04-04 21:48:20,584 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2152: No IPv6 address will be assigned
INFO 2026-04-04 21:48:21,009 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2318: Setting up share.ldb
INFO 2026-04-04 21:48:21,125 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2322: Setting up secrets.ldb
INFO 2026-04-04 21:48:21,206 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2327: Setting up the registry
INFO 2026-04-04 21:48:21,439 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2330: Setting up the privileges database
INFO 2026-04-04 21:48:21,572 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2333: Setting up idmap db
INFO 2026-04-04 21:48:21,670 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2340: Setting up SAM db
INFO 2026-04-04 21:48:21,714 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #886: Setting up sam.ldb partitions and settings
INFO 2026-04-04 21:48:21,717 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #898: Setting up sam.ldb rootDSE
INFO 2026-04-04 21:48:21,732 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1320: Pre-loading the Samba 4 and AD schema
Unable to determine the DomainSID, can not enforce uniqueness constraint on local domainSIDs

INFO 2026-04-04 21:48:21,818 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2432: A Kerberos configuration suitable for Samba AD has been generated at /var/lib/samba/private/krb5.conf
INFO 2026-04-04 21:48:21,819 pid:3279 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2434: Merge the contents of this file with your system krb5.conf or replace it with this one. Do not create a symlink!
Provision OK for domain DN DC=den,DC=skv
INFO 2026-04-04 21:48:21,845 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1007: Starting replication
Schema-DN[CN=Schema,CN=Configuration,DC=den,DC=skv] objects[402/1770] linked_values[0/0]
Schema-DN[CN=Schema,CN=Configuration,DC=den,DC=skv] objects[804/1770] linked_values[0/0]
Schema-DN[CN=Schema,CN=Configuration,DC=den,DC=skv] objects[1206/1770] linked_values[0/0]
Schema-DN[CN=Schema,CN=Configuration,DC=den,DC=skv] objects[1608/1770] linked_values[0/0]
Schema-DN[CN=Schema,CN=Configuration,DC=den,DC=skv] objects[1770/1770] linked_values[0/0]
Analyze and apply schema objects
Partition[CN=Configuration,DC=den,DC=skv] objects[402/1732] linked_values[0/1]
Partition[CN=Configuration,DC=den,DC=skv] objects[804/1732] linked_values[0/1]
Partition[CN=Configuration,DC=den,DC=skv] objects[1206/1732] linked_values[0/1]
Partition[CN=Configuration,DC=den,DC=skv] objects[1608/1732] linked_values[0/1]
Partition[CN=Configuration,DC=den,DC=skv] objects[1732/1732] linked_values[66/66]
Replicating critical objects from the base DN of the domain
Partition[DC=den,DC=skv] objects[98/98] linked_values[24/24]
Partition[DC=den,DC=skv] objects[289/289] linked_values[28/28]
Done with always replicated NC (base, config, schema)
Replicating DC=DomainDnsZones,DC=den,DC=skv
Partition[DC=DomainDnsZones,DC=den,DC=skv] objects[45/45] linked_values[0/0]
Replicating DC=ForestDnsZones,DC=den,DC=skv
Partition[DC=ForestDnsZones,DC=den,DC=skv] objects[18/18] linked_values[0/0]
Exop on[CN=RID Manager$,CN=System,DC=den,DC=skv] objects[3] linked_values[0]
INFO 2026-04-04 21:48:28,014 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1127: Committing SAM database - this may take some time
Repacking database from v1 to v2 format (first record CN=Foreign-Identifier,CN=Schema,CN=Configuration,DC=den,DC=skv)
Repack: re-packed 10000 records so far
Repacking database from v1 to v2 format (first record CN=nTFRSSettings-Display,CN=415,CN=DisplaySpecifiers,CN=Configuration,DC=den,DC=skv)
Repacking database from v1 to v2 format (first record DC=e.root-servers.net,DC=RootDNSServers,CN=MicrosoftDNS,DC=DomainDnsZones,DC=den,DC=skv)
Repacking database from v1 to v2 format (first record CN=Deleted Objects,DC=ForestDnsZones,DC=den,DC=skv)
Repacking database from v1 to v2 format (first record CN=c3c927a6-cc1d-47c0-966b-be8f9b63d991,CN=Operations,CN=DomainUpdates,CN=System,DC=den,DC=skv)
INFO 2026-04-04 21:48:30,547 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1147: Committed SAM database
INFO 2026-04-04 21:48:30,556 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1223: Adding 1 remote DNS records for ALTSRV3.den.skv
INFO 2026-04-04 21:48:30,677 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1285: Adding DNS A record ALTSRV3.den.skv for IPv4 IP: 192.168.100.252
INFO 2026-04-04 21:48:30,770 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1313: Adding DNS CNAME record 187804f5-5676-455e-9e5c-22603e39faef._msdcs.den.skv for ALTSRV3.den.skv
INFO 2026-04-04 21:48:30,851 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1338: All other DNS records (like _ldap SRV records) will be created samba_dnsupdate on first startup
INFO 2026-04-04 21:48:30,852 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1344: Replicating new DNS records in DC=DomainDnsZones,DC=den,DC=skv
Partition[DC=DomainDnsZones,DC=den,DC=skv] objects[2/2] linked_values[0/0]
INFO 2026-04-04 21:48:30,931 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1344: Replicating new DNS records in DC=ForestDnsZones,DC=den,DC=skv
Partition[DC=ForestDnsZones,DC=den,DC=skv] objects[2/2] linked_values[0/0]
INFO 2026-04-04 21:48:30,990 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1359: Sending DsReplicaUpdateRefs for all the replicated partitions
INFO 2026-04-04 21:48:31,114 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1389: Setting isSynchronized and dsServiceName
INFO 2026-04-04 21:48:31,138 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1404: Setting up secrets database
INFO 2026-04-04 21:48:31,324 pid:3279 /usr/lib64/samba-dc/python3.9/samba/join.py #1666: Joined domain DEN (SID S-1-5-21-3844159431-4187069331-1753675981) as a DC
```

</details>

## Запуск вторичного сервера и проверки
```bash
# Входим под УЗ в группе AD 'Domain Admins'
kinit -V smaba_u1

# Запуск службы
systemctl \
enable --now \
samba
```
```log
Synchronizing state of samba.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable samba
Created symlink /etc/systemd/system/multi-user.target.wants/samba.service → /lib/systemd/system/samba.service.
```

```bash
samba-tool dns \
add \
altsrv2.den.skv \
100.168.192.in-addr.arpa \
252 PTR \
altsrv3.den.skv \
-U smaba_u1
```
```log
Password for [DEN\smaba_u1]:
Record added successfully
```
```bash
# Заменяем ip DNS на самого себя и основной DC после запуска служб Домена
cat > /etc/net/ifaces/ens19/resolv.conf<<'EOF'
nameserver 127.0.0.1
nameserver 192.168.100.253
search den.skv
EOF

# Применение изменения настроек resolvconf
resolvconf -a \
ens19 \
< /etc/net/ifaces/ens19/resolv.conf

# Перезапуск службы etcnet управления сетью
systemctl \
restart \
network

# Перезапуск интерфейса
ifdown ens19 \
; ifup ens19
```
### проверки
```bash
resolvconf -l
```
```log
# resolv.conf from ens19
nameserver 127.0.0.1
nameserver 192.168.100.253
search den.skv
```
```bash
host den.skv
```
```log
den.skv has address 192.168.100.253
den.skv has address 192.168.100.252
```
```bash
host -t NS den.skv
```
```log
den.skv name server altsrv2.den.skv.
den.skv name server altsrv3.den.skv.
```
```bash
host ya.ru 127.0.0.1
```
```log
Using domain server:
Name: 127.0.0.1
Address: 127.0.0.1#53
Aliases: 

ya.ru has address 5.255.255.242
ya.ru has address 77.88.55.242
ya.ru has address 77.88.44.242
ya.ru has IPv6 address 2a02:6b8::2:242
ya.ru mail is handled by 10 mx.yandex.ru.
```
```bash
host ya.ru altsrv2.den.skv
```
```log
Using domain server:
Name: altsrv2.den.skv
Address: 192.168.100.253#53
Aliases: 

ya.ru has address 77.88.55.242
ya.ru has address 5.255.255.242
ya.ru has address 77.88.44.242
ya.ru has IPv6 address 2a02:6b8::2:242
ya.ru mail is handled by 10 mx.yandex.ru.
```
```bash
host -t SRV _ldap._tcp.den.skv
```
```log
_ldap._tcp.den.skv has SRV record 0 100 389 altsrv2.den.skv.
_ldap._tcp.den.skv has SRV record 0 100 389 altsrv3.den.skv
```
```bash
samba-tool computer \
list
```
```log
ALTSRV3$
ALTSRV2$
ALTWKS2$
```
```bash
journalctl -efu samba
```

<details>
<summary>Вывод журнала после первого включения</summary>

```log
Apr 04 21:50:05 altsrv3.den.skv systemd[1]: Starting Samba AD Daemon...
Apr 04 21:50:05 altsrv3.den.skv samba[3410]: [2026/04/04 21:50:05.762025,  0] ../../source4/samba/server.c:633(binary_smbd_main)
Apr 04 21:50:05 altsrv3.den.skv samba[3410]:   samba version 4.19.9-alt9 started.
Apr 04 21:50:05 altsrv3.den.skv samba[3410]:   Copyright Andrew Tridgell and the Samba Team 1992-2023
Apr 04 21:50:05 altsrv3.den.skv samba[3410]: [2026/04/04 21:50:05.763331,  0] ../../lib/util/become_daemon.c:150(daemon_status)
Apr 04 21:50:05 altsrv3.den.skv samba[3410]:   daemon 'samba' : Starting process...
Apr 04 21:50:06 altsrv3.den.skv samba[3424]: [2026/04/04 21:50:06.106462,  0] ../../source4/lib/tls/tlscert.c:67(tls_cert_generate)
Apr 04 21:50:06 altsrv3.den.skv samba[3424]:   Attempting to autogenerate TLS self-signed keys for https for hostname 'ALTSRV3.den.skv'
Apr 04 21:50:06 altsrv3.den.skv systemd[1]: Started Samba AD Daemon.
Apr 04 21:50:06 altsrv3.den.skv smbd[3416]: [2026/04/04 21:50:06.173833,  0] ../../source3/smbd/server.c:1746(main)
Apr 04 21:50:06 altsrv3.den.skv smbd[3416]:   smbd version 4.19.9-alt9 started.
Apr 04 21:50:06 altsrv3.den.skv smbd[3416]:   Copyright Andrew Tridgell and the Samba Team 1992-2023
Apr 04 21:50:06 altsrv3.den.skv winbindd[3448]: [2026/04/04 21:50:06.206692,  0] ../../source3/winbindd/winbindd.c:1433(main)
Apr 04 21:50:06 altsrv3.den.skv winbindd[3448]:   winbindd version 4.19.9-alt9 started.
Apr 04 21:50:06 altsrv3.den.skv winbindd[3448]:   Copyright Andrew Tridgell and the Samba Team 1992-2023
Apr 04 21:50:08 altsrv3.den.skv samba[3424]: [2026/04/04 21:50:08.624378,  0] ../../source4/lib/tls/tlscert.c:154(tls_cert_generate)
Apr 04 21:50:08 altsrv3.den.skv samba[3424]:   TLS self-signed keys generated OK
```

</details>

### Запуск обновления записей DNS
```bash
samba_dnsupdate --verbose --all-names
```

<details>
<summary>Вывод синхронизации</summary>

```log
IPs: ['192.168.100.252']
scavenging requires update: A altsrv3.den.skv 192.168.100.252
scavenging requires update: CNAME 187804f5-5676-455e-9e5c-22603e39faef._msdcs.den.skv altsrv3.den.skv
scavenging requires update: NS den.skv altsrv3.den.skv
scavenging requires update: NS _msdcs.den.skv altsrv3.den.skv
scavenging requires update: A den.skv 192.168.100.252
scavenging requires update: SRV _ldap._tcp.den.skv altsrv3.den.skv 389
scavenging requires update: SRV _ldap._tcp.dc._msdcs.den.skv altsrv3.den.skv 389
scavenging requires update: SRV _ldap._tcp.78e9bf80-9732-40c8-9127-515df539e577.domains._msdcs.den.skv altsrv3.den.skv 389
scavenging requires update: SRV _kerberos._tcp.den.skv altsrv3.den.skv 88
scavenging requires update: SRV _kerberos._udp.den.skv altsrv3.den.skv 88
scavenging requires update: SRV _kerberos._tcp.dc._msdcs.den.skv altsrv3.den.skv 88
scavenging requires update: SRV _kpasswd._tcp.den.skv altsrv3.den.skv 464
scavenging requires update: SRV _kpasswd._udp.den.skv altsrv3.den.skv 464
scavenging requires update: SRV _ldap._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 389
scavenging requires update: SRV _ldap._tcp.Default-First-Site-Name._sites.dc._msdcs.den.skv altsrv3.den.skv 389
scavenging requires update: SRV _kerberos._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 88
scavenging requires update: SRV _kerberos._tcp.Default-First-Site-Name._sites.dc._msdcs.den.skv altsrv3.den.skv 88
scavenging requires update: A gc._msdcs.den.skv 192.168.100.252
scavenging requires update: SRV _gc._tcp.den.skv altsrv3.den.skv 3268
scavenging requires update: SRV _ldap._tcp.gc._msdcs.den.skv altsrv3.den.skv 3268
scavenging requires update: SRV _gc._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 3268
scavenging requires update: SRV _ldap._tcp.Default-First-Site-Name._sites.gc._msdcs.den.skv altsrv3.den.skv 3268
scavenging requires update: A DomainDnsZones.den.skv 192.168.100.252
scavenging requires update: SRV _ldap._tcp.DomainDnsZones.den.skv altsrv3.den.skv 389
scavenging requires update: SRV _ldap._tcp.Default-First-Site-Name._sites.DomainDnsZones.den.skv altsrv3.den.skv 389
scavenging requires update: A ForestDnsZones.den.skv 192.168.100.252
scavenging requires update: SRV _ldap._tcp.ForestDnsZones.den.skv altsrv3.den.skv 389
scavenging requires update: SRV _ldap._tcp.Default-First-Site-Name._sites.ForestDnsZones.den.skv altsrv3.den.skv 389
28 DNS updates and 0 DNS deletes needed
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
update(nsupdate): A altsrv3.den.skv 192.168.100.252
Calling nsupdate for A altsrv3.den.skv 192.168.100.252 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
altsrv3.den.skv.        900     IN      A       192.168.100.252

update(nsupdate): CNAME 187804f5-5676-455e-9e5c-22603e39faef._msdcs.den.skv altsrv3.den.skv
Calling nsupdate for CNAME 187804f5-5676-455e-9e5c-22603e39faef._msdcs.den.skv altsrv3.den.skv (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
187804f5-5676-455e-9e5c-22603e39faef._msdcs.den.skv. 900 IN CNAME altsrv3.den.skv.

update(nsupdate): NS den.skv altsrv3.den.skv
Calling nsupdate for NS den.skv altsrv3.den.skv (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
den.skv.                900     IN      NS      altsrv3.den.skv.

update(nsupdate): NS _msdcs.den.skv altsrv3.den.skv
Calling nsupdate for NS _msdcs.den.skv altsrv3.den.skv (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_msdcs.den.skv.         900     IN      NS      altsrv3.den.skv.

update(nsupdate): A den.skv 192.168.100.252
Calling nsupdate for A den.skv 192.168.100.252 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
den.skv.                900     IN      A       192.168.100.252

update(nsupdate): SRV _ldap._tcp.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.den.skv.     900     IN      SRV     0 100 389 altsrv3.den.skv.

update(nsupdate): SRV _ldap._tcp.dc._msdcs.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.dc._msdcs.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.dc._msdcs.den.skv. 900 IN    SRV     0 100 389 altsrv3.den.skv.

update(nsupdate): SRV _ldap._tcp.78e9bf80-9732-40c8-9127-515df539e577.domains._msdcs.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.78e9bf80-9732-40c8-9127-515df539e577.domains._msdcs.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.78e9bf80-9732-40c8-9127-515df539e577.domains._msdcs.den.skv. 900 IN SRV 0 100 389 altsrv3.den.skv.

update(nsupdate): SRV _kerberos._tcp.den.skv altsrv3.den.skv 88
Calling nsupdate for SRV _kerberos._tcp.den.skv altsrv3.den.skv 88 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_kerberos._tcp.den.skv. 900     IN      SRV     0 100 88 altsrv3.den.skv.

update(nsupdate): SRV _kerberos._udp.den.skv altsrv3.den.skv 88
Calling nsupdate for SRV _kerberos._udp.den.skv altsrv3.den.skv 88 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_kerberos._udp.den.skv. 900     IN      SRV     0 100 88 altsrv3.den.skv.

update(nsupdate): SRV _kerberos._tcp.dc._msdcs.den.skv altsrv3.den.skv 88
Calling nsupdate for SRV _kerberos._tcp.dc._msdcs.den.skv altsrv3.den.skv 88 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_kerberos._tcp.dc._msdcs.den.skv. 900 IN SRV    0 100 88 altsrv3.den.skv.

update(nsupdate): SRV _kpasswd._tcp.den.skv altsrv3.den.skv 464
Calling nsupdate for SRV _kpasswd._tcp.den.skv altsrv3.den.skv 464 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_kpasswd._tcp.den.skv.  900     IN      SRV     0 100 464 altsrv3.den.skv.

update(nsupdate): SRV _kpasswd._udp.den.skv altsrv3.den.skv 464
Calling nsupdate for SRV _kpasswd._udp.den.skv altsrv3.den.skv 464 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_kpasswd._udp.den.skv.  900     IN      SRV     0 100 464 altsrv3.den.skv.

update(nsupdate): SRV _ldap._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.Default-First-Site-Name._sites.den.skv. 900 IN SRV 0 100 389 altsrv3.den.skv.

update(nsupdate): SRV _ldap._tcp.Default-First-Site-Name._sites.dc._msdcs.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.Default-First-Site-Name._sites.dc._msdcs.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.Default-First-Site-Name._sites.dc._msdcs.den.skv. 900 IN SRV 0 100 389 altsrv3.den.skv.

update(nsupdate): SRV _kerberos._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 88
Calling nsupdate for SRV _kerberos._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 88 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_kerberos._tcp.Default-First-Site-Name._sites.den.skv. 900 IN SRV 0 100 88 altsrv3.den.skv.

update(nsupdate): SRV _kerberos._tcp.Default-First-Site-Name._sites.dc._msdcs.den.skv altsrv3.den.skv 88
Calling nsupdate for SRV _kerberos._tcp.Default-First-Site-Name._sites.dc._msdcs.den.skv altsrv3.den.skv 88 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_kerberos._tcp.Default-First-Site-Name._sites.dc._msdcs.den.skv. 900 IN SRV 0 100 88 altsrv3.den.skv.

update(nsupdate): A gc._msdcs.den.skv 192.168.100.252
Calling nsupdate for A gc._msdcs.den.skv 192.168.100.252 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
gc._msdcs.den.skv.      900     IN      A       192.168.100.252

update(nsupdate): SRV _gc._tcp.den.skv altsrv3.den.skv 3268
Calling nsupdate for SRV _gc._tcp.den.skv altsrv3.den.skv 3268 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_gc._tcp.den.skv.       900     IN      SRV     0 100 3268 altsrv3.den.skv.

update(nsupdate): SRV _ldap._tcp.gc._msdcs.den.skv altsrv3.den.skv 3268
Calling nsupdate for SRV _ldap._tcp.gc._msdcs.den.skv altsrv3.den.skv 3268 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.gc._msdcs.den.skv. 900 IN    SRV     0 100 3268 altsrv3.den.skv.

update(nsupdate): SRV _gc._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 3268
Calling nsupdate for SRV _gc._tcp.Default-First-Site-Name._sites.den.skv altsrv3.den.skv 3268 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_gc._tcp.Default-First-Site-Name._sites.den.skv. 900 IN SRV 0 100 3268 altsrv3.den.skv.

update(nsupdate): SRV _ldap._tcp.Default-First-Site-Name._sites.gc._msdcs.den.skv altsrv3.den.skv 3268
Calling nsupdate for SRV _ldap._tcp.Default-First-Site-Name._sites.gc._msdcs.den.skv altsrv3.den.skv 3268 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.Default-First-Site-Name._sites.gc._msdcs.den.skv. 900 IN SRV 0 100 3268 altsrv3.den.skv.

update(nsupdate): A DomainDnsZones.den.skv 192.168.100.252
Calling nsupdate for A DomainDnsZones.den.skv 192.168.100.252 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
DomainDnsZones.den.skv. 900     IN      A       192.168.100.252

update(nsupdate): SRV _ldap._tcp.DomainDnsZones.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.DomainDnsZones.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.DomainDnsZones.den.skv. 900 IN SRV   0 100 389 altsrv3.den.skv.

update(nsupdate): SRV _ldap._tcp.Default-First-Site-Name._sites.DomainDnsZones.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.Default-First-Site-Name._sites.DomainDnsZones.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.Default-First-Site-Name._sites.DomainDnsZones.den.skv. 900 IN SRV 0 100 389 altsrv3.den.skv.

update(nsupdate): A ForestDnsZones.den.skv 192.168.100.252
Calling nsupdate for A ForestDnsZones.den.skv 192.168.100.252 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
ForestDnsZones.den.skv. 900     IN      A       192.168.100.252

update(nsupdate): SRV _ldap._tcp.ForestDnsZones.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.ForestDnsZones.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.ForestDnsZones.den.skv. 900 IN SRV   0 100 389 altsrv3.den.skv.

update(nsupdate): SRV _ldap._tcp.Default-First-Site-Name._sites.ForestDnsZones.den.skv altsrv3.den.skv 389
Calling nsupdate for SRV _ldap._tcp.Default-First-Site-Name._sites.ForestDnsZones.den.skv altsrv3.den.skv 389 (add)
Successfully obtained Kerberos ticket to DNS/altsrv3.den.skv as ALTSRV3$
Outgoing update query:
;; ->>HEADER<<- opcode: UPDATE, status: NOERROR, id:      0
;; flags:; ZONE: 0, PREREQ: 0, UPDATE: 0, ADDITIONAL: 0
;; UPDATE SECTION:
_ldap._tcp.Default-First-Site-Name._sites.ForestDnsZones.den.skv. 900 IN SRV 0 100 389 altsrv3.den.skv.
```

</details>

### Состояние репликации
```bash
samba-tool drs \
showrepl
```

<details>
<summary>Состояние репликации altsrv3 (Вторичнвый DC)</summary>

```log
Default-First-Site-Name\ALTSRV3
DSA Options: 0x00000001
DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
DSA invocationId: 248fbb8c-2fe7-4ea2-b9fe-9e7c5091330f

==== INBOUND NEIGHBORS ====

CN=Configuration,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ Sat Apr  4 22:00:21 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:00:21 2026 MSK

DC=ForestDnsZones,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ Sat Apr  4 22:00:21 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:00:21 2026 MSK

DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ Sat Apr  4 22:00:21 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:00:21 2026 MSK

CN=Schema,CN=Configuration,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ Sat Apr  4 22:00:21 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:00:21 2026 MSK

DC=DomainDnsZones,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ Sat Apr  4 22:00:21 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:00:21 2026 MSK

==== OUTBOUND NEIGHBORS ====

CN=Configuration,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

DC=ForestDnsZones,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

CN=Schema,CN=Configuration,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

DC=DomainDnsZones,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV2 via RPC
                DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

==== KCC CONNECTION OBJECTS ====

Connection --
        Connection name: c598c140-3a71-4826-a4fa-0215d7587eab
        Enabled        : TRUE
        Server DNS name : altsrv2.den.skv
        Server DN name  : CN=NTDS Settings,CN=ALTSRV2,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=den,DC=skv
                TransportType: RPC
                options: 0x00000001
Warning: No NC replicated for Connection!
```

</details>

<details>
<summary>Состояние репликации altsrv2 (Основной DC)</summary>

```log
Default-First-Site-Name\ALTSRV2
DSA Options: 0x00000001
DSA object GUID: efd4f526-cd73-4346-acd0-11c841e95d30
DSA invocationId: 58828b5a-9da2-4759-b6b3-ac5fff1eef46

==== INBOUND NEIGHBORS ====

CN=Configuration,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ Sat Apr  4 22:02:41 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:02:41 2026 MSK

DC=ForestDnsZones,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ Sat Apr  4 22:02:41 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:02:41 2026 MSK

DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ Sat Apr  4 22:02:41 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:02:41 2026 MSK

CN=Schema,CN=Configuration,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ Sat Apr  4 22:02:42 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:02:42 2026 MSK

DC=DomainDnsZones,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ Sat Apr  4 22:02:41 2026 MSK was successful
                0 consecutive failure(s).
                Last success @ Sat Apr  4 22:02:41 2026 MSK

==== OUTBOUND NEIGHBORS ====

CN=Configuration,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

DC=ForestDnsZones,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

CN=Schema,CN=Configuration,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

DC=DomainDnsZones,DC=den,DC=skv
        Default-First-Site-Name\ALTSRV3 via RPC
                DSA object GUID: 187804f5-5676-455e-9e5c-22603e39faef
                Last attempt @ NTTIME(0) was successful
                0 consecutive failure(s).
                Last success @ NTTIME(0)

==== KCC CONNECTION OBJECTS ====

Connection --
        Connection name: 042737b3-4919-4f4a-9c50-139cf9c312a2
        Enabled        : TRUE
        Server DNS name : altsrv3.den.skv
        Server DN name  : CN=NTDS Settings,CN=ALTSRV3,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=den,DC=skv
                TransportType: RPC
                options: 0x00000001
Warning: No NC replicated for Connection!
```

</details>

### Подготовленного конфига Вторичного DHCP
```bash
cat > /home/sysadmin/dhcpd.conf.working <<'EOF'
authoritative;
ddns-update-style none;

omapi-port 7911;
omapi-key omapi_key;
key "omapi_key" {
        algorithm hmac-md5;
        secret "X1fpFP2WBXkOtsSj8kVwRw==";
};

failover peer "dhcp-failover" {
  secondary;
  # Полное DNS-имя основного DHCP-сервера
  address altsrv3.den.skv;
  port 647;
  # Полное DNS-имя имя резервного DHCP-сервера
  peer address altsrv2.den.skv;
  peer port 847;
  max-response-delay 20;
  max-unacked-updates 5;
  load balance max seconds 2;
}

subnet 192.168.100.0 netmask 255.255.255.0 {
        option broadcast-address        192.168.100.255;
        option time-offset              0;
        option routers                  192.168.100.1;
        option subnet-mask              255.255.255.0;

        option nis-domain               "den.skv";
        option domain-name              "den.skv";
        option domain-name-servers      192.168.100.253, 192.168.100.252;
        option ntp-servers              192.168.100.253, 192.168.100.252;

        pool {
            failover peer "dhcp-failover";
            default-lease-time 172800;
            max-lease-time 259200;
            range 192.168.100.50 192.168.100.254;
        }
}

on commit {
set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
set ClientName = pick-first-value(option host-name, config-option host-name, client-name, noname);
log(concat("Commit: IP: ", ClientIP, " DHCID: ", ClientDHCID, " Name: ", ClientName));
execute("/usr/local/bin/dhcp-dyndns.sh", "add", ClientIP, ClientDHCID, ClientName);
}

on release {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
log(concat("Release: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, ClientDHCID);
}

on expiry {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
log(concat("Expired: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, "", "0");
}

host altsrv1.den.skv {
  hardware ethernet ee:a8:71:80:72:45;
  infinite-is-reserved on;
  fixed-address 192.168.100.254;
}

host altsrv2.den.skv {
  hardware ethernet 36:dd:7b:0c:81:2d;
  infinite-is-reserved on;
  fixed-address 192.168.100.253;
}

host altsrv3.den.skv {
  hardware ethernet ae:49:e7:f8:62:2d;
  infinite-is-reserved on;
  fixed-address 192.168.100.252;
}

host altsrv4.den.skv {
  hardware ethernet ce:94:fd:b4:54:40;
  infinite-is-reserved on;
  fixed-address 192.168.100.251;
}
EOF
```

```bash
# Проверка наличия файл
find /home/sysadmin/dhcpd.conf.working 
```
```log
/home/sysadmin/dhcpd.conf.working
```

### Копирование подготовленного конфига
```bash
cp -v /home/sysadmin/dhcpd.conf.working \
/etc/dhcp/dhcpd.conf
```
```log
'/home/sysadmin/dhcpd.conf.working' -> '/etc/dhcp/dhcpd.conf'
```
```bash
cp -v /home/sysadmin/dhcpd.conf.working \
/etc/dhcp/
```
```log
'/home/sysadmin/dhcpd.conf.working' -> '/etc/dhcp/dhcpd.conf.working'
```
```bash
# проверка конфига
dhcpd -t
```

<details>
<summary>Вывод рабочего конфига</summary>

```log
Internet Systems Consortium DHCP Server 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/
Config file: /etc/dhcp/dhcpd.conf
Database file: /state/dhcpd.leases
PID file: /var/run/dhcpd.pid
```
</details>

## Подготовка Взаимодействия с DNS записями Вторичного DHCP
```bash
# Копирование скрипт и keytab-файл с Основного DC\DHCP на Вторичный из-под локального пользователя sysadmin
ssh -t \
-o StrictHostKeyChecking=accept-new \
sysadmin@altsrv2 \
"su - \
-c 'scp /usr/local/bin/dhcp-dyndns.sh \
/etc/dhcp/dhcpduser.keytab \
sysadmin@altsrv3:~/'"
```
```bash
# Проверка полученных файлов
find /home/sysadmin/dhcp*
```
```log
/home/sysadmin/dhcp-dyndns.sh
/home/sysadmin/dhcpd.conf.working
/home/sysadmin/dhcpduser.keytab
```
### Скрипт взаимодействия с DNS записями AD
```bash
# Перенос в каталог для вызова скрипта по имени файла
cp -v /home/sysadmin/dhcp-dyndns.sh \
/usr/local/bin/
```
```log
'/home/sysadmin/dhcp-dyndns.sh' -> '/usr/local/bin/dhcp-dyndns.sh'
```
```bash
# Делаем скрипт исполняемым и доступным
chmod -v 755 \
/usr/local/bin/dhcp-dyndns.sh
```
```log
mode of '/usr/local/bin/dhcp-dyndns.sh' retained as 0755 (rwxr-xr-x)
```
### Файл kerberos УЗ dhcpduser для взаимодействия с DNS записями AD
```bash
# Перенос Файла kerberos в каталог службы dhcpd
cp -v /home/sysadmin/dhcpduser.keytab \
/etc/dhcp/
```
```log
'/home/sysadmin/dhcpduser.keytab' -> '/etc/dhcp/dhcpduser.keytab'
```
```bash
# Смена владельца доступа до файла kerberos
chown -v dhcpd:dhcp \
/etc/dhcp/dhcpduser.keytab
```
```log
changed ownership of '/etc/dhcp/dhcpduser.keytab' from root:root to dhcpd:dhcp
```
```bash
# Ограничение прав на работу с файлом Kerberos
chmod -v 400 \
/etc/dhcp/dhcpduser.keytab
```
```
mode of '/etc/dhcp/dhcpduser.keytab' retained as 0400 (r--------)
```

## Отключение chroot для DHCP-сервера 
```bash
control dhcpd-chroot \
disabled
```
### проверка состояния chroot через control
```bash
control dhcpd-chroot
```
```log
disabled
```
### Проверка правильности конфгиа
```bash
dhcpd -t
```

<details>
<summary>Вывод корректности конфигурации DHCP</summary>

```log
Internet Systems Consortium DHCP Server 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/
Config file: /etc/dhcp/dhcpd.conf
Database file: /state/dhcpd.leases
PID file: /var/run/dhcpd.pid
```

</details>

## Запуск DHCP с Подготовленными настройками Вторичного DHCP

```bash
# ЗАпуск службы
systemctl \
enable \
--now dhcpd
```
```log
Executing: /lib/systemd/systemd-sysv-install enable dhcpd
Created symlink /etc/systemd/system/multi-user.target.wants/dhcpd.service → /lib/systemd/system/dhcpd.servic
```
```bash
# Вывод состояние службы
systemctl \
status \
dhcpd \
| grep Active
```
```log
Active: active (running) since Sat 2026-04-04 22:18:03 MSK; 6s ago
```
```bash
journalctl -efu dhcpd --no-pager
```

<details>
<summary>Вывод запуска Вторичного DHCP в режиме failover</summary>

```log
Apr 04 22:18:03 altsrv3.den.skv systemd[1]: Starting DHCPv4 Server Daemon...
Apr 04 22:18:03 altsrv3.den.skv systemd[1]: Started DHCPv4 Server Daemon.
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Internet Systems Consortium DHCP Server 4.4.3-P1
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Copyright 2004-2022 Internet Systems Consortium.
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: All rights reserved.
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: For info, please visit https://www.isc.org/software/dhcp/
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Config file: /etc/dhcp/dhcpd.conf
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Database file: /var/lib/dhcp/dhcpd/state/dhcpd.leases
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: PID file: /var/run/dhcpd.pid
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Listening on LPF/ens19/ae:49:e7:f8:62:2d/192.168.100.0/24
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Sending on   LPF/ens19/ae:49:e7:f8:62:2d/192.168.100.0/24
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Sending on   Socket/fallback/fallback-net
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Wrote 0 deleted host decls to leases file.
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Wrote 0 new dynamic host decls to leases file.
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Wrote 0 leases to leases file.
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: I move from recover to startup
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Server starting service.
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: peer moves from unknown-state to recover
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: requesting full update from peer
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: I move from startup to recover
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Sent update request all message to dhcp-failover
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Update request all from dhcp-failover: sending update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Received update request while old update still flying!  Silently discarding old request.
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: Update request all from dhcp-failover: sending update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.50 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.51 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.52 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.53 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.54 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.55 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.56 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.57 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.58 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.59 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.60 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.61 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.62 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.63 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.64 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.65 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.66 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.67 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.68 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.69 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.70 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.71 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.72 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.73 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.74 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.75 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.76 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.77 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.78 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.79 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.80 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.81 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.82 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.83 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.84 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.85 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.86 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.87 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.88 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.89 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.90 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.91 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.92 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.93 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.94 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.95 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.96 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.97 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.98 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:03 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.99 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.100 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.101 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.102 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.103 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.104 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.105 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.106 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.107 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.108 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.109 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.110 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.111 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.112 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.113 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.114 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.115 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.116 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.117 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.118 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.119 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.120 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.121 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.122 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.123 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.124 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.125 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.126 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.127 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.128 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.129 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.130 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.131 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.132 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.133 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.134 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.135 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.136 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.137 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.138 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.139 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.140 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.141 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.142 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.143 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.144 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.145 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.146 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.147 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.148 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.149 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.150 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.151 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.152 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.153 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.154 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.155 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.156 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.157 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.158 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.159 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.160 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.161 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.162 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.163 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.164 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.165 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.166 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.167 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.168 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.169 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.170 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.171 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.172 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.173 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.174 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.175 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.176 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.177 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.178 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.179 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.180 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.181 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.182 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.183 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.184 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.185 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.186 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.187 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.188 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.189 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.190 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.191 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.192 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.193 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.194 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.195 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.196 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.197 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.198 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.199 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.200 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.201 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.202 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.203 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.204 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.205 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.206 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.207 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.208 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.209 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.210 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.211 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.212 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.213 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.214 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.215 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.216 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.217 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.218 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.219 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.220 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.221 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.222 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.223 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.224 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.225 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.226 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.227 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.228 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.229 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.230 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.231 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.232 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.233 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.234 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.235 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.236 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.237 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.238 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.239 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.240 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.241 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.242 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.243 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.244 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.245 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.246 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.247 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.248 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.249 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.250 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.251 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.252 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.253 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: bind update on 192.168.100.254 from dhcp-failover rejected: incoming update is less critical than outgoing update
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: Sent update done message to dhcp-failover
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: peer update completed.
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: I move from recover to recover-done
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: peer moves from recover to recover-done
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: Both servers have entered recover-done!
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: I move from recover-done to normal
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: balancing pool 561bc8094ad0 192.168.100.0/24  total 205  free 204  backup 0  lts -102  max-own (+/-)20
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: balanced pool 561bc8094ad0 192.168.100.0/24  total 205  free 204  backup 0  lts -102  max-misbal 31
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: peer moves from recover-done to normal
Apr 04 22:18:04 altsrv3.den.skv dhcpd[5542]: failover peer dhcp-failover: Both servers normal
Apr 04 22:19:04 altsrv3.den.skv dhcpd[5542]: balancing pool 561bc8094ad0 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-own (+/-)20
Apr 04 22:19:04 altsrv3.den.skv dhcpd[5542]: balanced pool 561bc8094ad0 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-misbal 31
Apr 04 22:22:05 altsrv3.den.skv dhcpd[5542]: Commit: IP: 192.168.100.50 DHCID: 6a:36:90:85:f6:66 Name: altwks2
Apr 04 22:22:05 altsrv3.den.skv dhcpd[5542]: execute_statement argv[0] = /usr/local/bin/dhcp-dyndns.sh
Apr 04 22:22:05 altsrv3.den.skv dhcpd[5542]: execute_statement argv[1] = add
Apr 04 22:22:05 altsrv3.den.skv dhcpd[5542]: execute_statement argv[2] = 192.168.100.50
Apr 04 22:22:05 altsrv3.den.skv dhcpd[5542]: execute_statement argv[3] = 6a:36:90:85:f6:66
Apr 04 22:22:05 altsrv3.den.skv dhcpd[5542]: execute_statement argv[4] = altwks2
Apr 04 22:22:06 altsrv3.den.skv dhcpd[5733]: 04-04-26 22:22:06 [dyndns] : Getting new ticket, old one has expired
Apr 04 22:22:06 altsrv3.den.skv dhcpd[5734]: kinit: Pre-authentication failed: Недопустимый аргумент while getting initial credentials
Apr 04 22:22:06 altsrv3.den.skv dhcpd[5735]: 04-04-26 22:22:06 [dyndns] : dhcpd kinit for dynamic DNS failed
Apr 04 22:22:06 altsrv3.den.skv dhcpd[5542]: execute: /usr/local/bin/dhcp-dyndns.sh exit status 256
Apr 04 22:22:06 altsrv3.den.skv dhcpd[5542]: DHCPREQUEST for 192.168.100.50 from 6a:36:90:85:f6:66 via ens19
Apr 04 22:22:06 altsrv3.den.skv dhcpd[5542]: DHCPACK on 192.168.100.50 to 6a:36:90:85:f6:66 (altwks2) via ens19
```

</details>


<details>
<summary>Вывод на основном DHCP в режиме failover</summary>

```log
Apr 04 22:17:50 altsrv2.den.skv dhcpd[4326]: socket.c:1069: epoll_ctl(DEL), 11: Bad file descriptor
Apr 04 22:17:50 altsrv2.den.skv dhcpd[4326]: socket.c:1069: epoll_ctl(DEL), 11: Bad file descriptor
Apr 04 22:17:55 altsrv2.den.skv dhcpd[4326]: socket.c:1069: epoll_ctl(DEL), 11: Bad file descriptor
Apr 04 22:17:55 altsrv2.den.skv dhcpd[4326]: socket.c:1069: epoll_ctl(DEL), 11: Bad file descriptor
Apr 04 22:18:00 altsrv2.den.skv dhcpd[4326]: socket.c:1069: epoll_ctl(DEL), 11: Bad file descriptor
Apr 04 22:18:00 altsrv2.den.skv dhcpd[4326]: socket.c:1069: epoll_ctl(DEL), 11: Bad file descriptor
Apr 04 22:18:03 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: peer moves from unknown-state to recover
Apr 04 22:18:03 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: requesting full update from peer
Apr 04 22:18:03 altsrv2.den.skv dhcpd[4326]: Sent update request all message to dhcp-failover
Apr 04 22:18:03 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: peer moves from recover to recover
Apr 04 22:18:03 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: requesting full update from peer
Apr 04 22:18:03 altsrv2.den.skv dhcpd[4326]: Sent update request all message to dhcp-failover
Apr 04 22:18:03 altsrv2.den.skv dhcpd[4326]: Update request all from dhcp-failover: sending update
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: Sent update done message to dhcp-failover
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: peer update completed.
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: I move from recover to recover-done
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: peer moves from recover to recover-done
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: Both servers have entered recover-done!
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: I move from recover-done to normal
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: balancing pool 5584c34d0b20 192.168.100.0/24  total 205  free 204  backup 0  lts 102  max-own (+/-)20
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: balanced pool 5584c34d0b20 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-misbal 31
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: Sending updates to dhcp-failover.
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: peer moves from recover-done to normal
Apr 04 22:18:04 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: Both servers normal
Apr 04 22:22:05 altsrv2.den.skv dhcpd[4326]: Commit: IP: 192.168.100.50 DHCID: 6a:36:90:85:f6:66 Name: altwks2
Apr 04 22:22:05 altsrv2.den.skv dhcpd[4326]: execute_statement argv[0] = /usr/local/bin/dhcp-dyndns.sh
Apr 04 22:22:05 altsrv2.den.skv dhcpd[4326]: execute_statement argv[1] = add
Apr 04 22:22:05 altsrv2.den.skv dhcpd[4326]: execute_statement argv[2] = 192.168.100.50
Apr 04 22:22:05 altsrv2.den.skv dhcpd[4326]: execute_statement argv[3] = 6a:36:90:85:f6:66
Apr 04 22:22:05 altsrv2.den.skv dhcpd[4326]: execute_statement argv[4] = altwks2
Apr 04 22:22:06 altsrv2.den.skv dhcpd[5220]: Correct 'A' record exists, not updating.
Apr 04 22:22:06 altsrv2.den.skv dhcpd[5246]: Correct 'PTR' record exists, not updating.
Apr 04 22:22:06 altsrv2.den.skv dhcpd[4326]: reuse_lease: lease age 4012 (secs) under 25% threshold, reply with unaltered, existing lease for 192.168.100.50
Apr 04 22:22:06 altsrv2.den.skv dhcpd[4326]: DHCPREQUEST for 192.168.100.50 from 6a:36:90:85:f6:66 (altwks2) via ens19
Apr 04 22:22:06 altsrv2.den.skv dhcpd[4326]: DHCPACK on 192.168.100.50 to 6a:36:90:85:f6:66 (altwks2) via ens19
```

</details>

## Настройка переключения failover-DHCP
### Создание failback конфига без failover опций на случай падения партнера
```bash
cat > /etc/dhcp/dhcpd-fallback.conf <<'EOF'
authoritative;
ddns-update-style none;

omapi-port 7911;
omapi-key omapi_key;
key "omapi_key" {
        algorithm hmac-md5;
        secret "X1fpFP2WBXkOtsSj8kVwRw==";
};

subnet 192.168.100.0 netmask 255.255.255.0 {
        option broadcast-address        192.168.100.255;
        option time-offset              0;
        option routers                  192.168.100.1;
        option subnet-mask              255.255.255.0;

        option nis-domain               "den.skv";
        option domain-name              "den.skv";
        option domain-name-servers      192.168.100.252, 192.168.100.253;
        option ntp-servers              192.168.100.252, 192.168.100.253;

        pool {
            default-lease-time 172800;
            max-lease-time 259200;
            range 192.168.100.50 192.168.100.254;
        }
}

on commit {
set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
set ClientName = pick-first-value(option host-name, config-option host-name, client-name, noname);
log(concat("Commit: IP: ", ClientIP, " DHCID: ", ClientDHCID, " Name: ", ClientName));
execute("/usr/local/bin/dhcp-dyndns.sh", "add", ClientIP, ClientDHCID, ClientName);
}

on release {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
log(concat("Release: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, ClientDHCID);
}

on expiry {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
log(concat("Expired: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, "", "0");
}

host altsrv1.den.skv {
  hardware ethernet ee:a8:71:80:72:45;
  infinite-is-reserved on;
  fixed-address 192.168.100.254;
}

host altsrv2.den.skv {
  hardware ethernet 36:dd:7b:0c:81:2d;
  infinite-is-reserved on;
  fixed-address 192.168.100.253;
}

host altsrv3.den.skv {
  hardware ethernet ae:49:e7:f8:62:2d;
  infinite-is-reserved on;
  fixed-address 192.168.100.252;
}

host altsrv4.den.skv {
  hardware ethernet ce:94:fd:b4:54:40;
  infinite-is-reserved on;
  fixed-address 192.168.100.251;
}
EOF
```
### Скрипт проверки и восстановления в случае сбоя DHCP-failover
```bash
cat > /usr/local/bin/dhcp-fallback.sh <<'EOF'
#!/bin/bash

if ! ping -c 2 -W 5 altsrv2.den.skv &>/dev/null; then
    logger "DHCP failover: partner unreachable, switching to fallback mode"
    
    # Перезапуск, только если нет бэкапа рабочего конфига
    if [ ! -f /etc/dhcp/dhcpd.conf.bak ]; then
        # Сохранить текущий конфиг
        rsync /etc/dhcp/dhcpd.conf{,.bak}
        # Заменяем на fallback-конфиг
        rsync /etc/dhcp/dhcpd{-fallback,}.conf
        # Перезапускаем службу
        systemctl restart dhcpd
    fi

else
    # Партнёр доступен
    logger "DHCP: partner is reachable, normal working"

    # Восстанавление конфига, только если есть бэкап
    if [ -f /etc/dhcp/dhcpd.conf.bak ]; then
        logger "DHCP: restoring original config from backup"
        mv -f /etc/dhcp/dhcpd.conf{.bak,}
        systemctl restart dhcpd
    fi
fi
EOF

chmod -v 755 \
/usr/local/bin/dhcp-fallback.sh
```
```log
mode of '/usr/local/bin/dhcp-fallback.sh' changed from 0644 (rw-r--r--) to 0755 (rwxr-xr-x)
```

### Создание timer systemd Для отслеживания
```bash
cat > /etc/systemd/system/dhcp-fallback.timer <<'EOF'
[Unit]
Description=Проверка DHCP failover партнера каждые 2 минуты

[Timer]
OnBootSec=1min
OnUnitActiveSec=2min
Unit=dhcp-fallback.service

[Install]
WantedBy=timers.target
EOF

# One-shot служба запускаемая таймером
cat > /etc/systemd/system/dhcp-fallback.service <<'EOF'
[Unit]
Description=DHCP Fallback Check
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/dhcp-fallback.sh
EOF
```
### Запуск созданного таймера проверки
```bash
systemctl \
enable --now \
dhcp-fallback.timer
```
```log
Created symlink /etc/systemd/system/timers.target.wants/dhcp-fallback.timer → /etc/systemd/system/dhcp-fallback.timer.
```

### проверка корректности конфига
```bash
dhcpd -t
```

<details>
<summary>вывод о корректности конфигурации DHCP</summary>

```log
Internet Systems Consortium DHCP Server 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/
Config file: /etc/dhcp/dhcpd.conf
Database file: /state/dhcpd.leases
PID file: /var/run/dhcpd.pid
```

</details>

### Перезапуск службы
```bash
systemctl \
restart \
dhcpd
```
```bash
# вывод журнала службы
journalctl -efu dhcpd --no-pager
```

<details>
<summary>Перезапуск DHCP со стороны Вторичного сервера</summary>

```log
Apr 04 22:29:37 altsrv3.den.skv systemd[1]: Stopping DHCPv4 Server Daemon...
Apr 04 22:29:37 altsrv3.den.skv systemd[1]: dhcpd.service: Deactivated successfully.
Apr 04 22:29:37 altsrv3.den.skv systemd[1]: Stopped DHCPv4 Server Daemon.
Apr 04 22:29:37 altsrv3.den.skv systemd[1]: dhcpd.service: Consumed 1.000s CPU time.
Apr 04 22:29:37 altsrv3.den.skv systemd[1]: Starting DHCPv4 Server Daemon...
Apr 04 22:29:37 altsrv3.den.skv systemd[1]: Started DHCPv4 Server Daemon.
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Internet Systems Consortium DHCP Server 4.4.3-P1
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Copyright 2004-2022 Internet Systems Consortium.
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: All rights reserved.
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: For info, please visit https://www.isc.org/software/dhcp/
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Config file: /etc/dhcp/dhcpd.conf
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Database file: /var/lib/dhcp/dhcpd/state/dhcpd.leases
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: PID file: /var/run/dhcpd.pid
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Listening on LPF/ens19/ae:49:e7:f8:62:2d/192.168.100.0/24
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Sending on   LPF/ens19/ae:49:e7:f8:62:2d/192.168.100.0/24
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Sending on   Socket/fallback/fallback-net
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Wrote 0 deleted host decls to leases file.
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Wrote 0 new dynamic host decls to leases file.
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Wrote 103 leases to leases file.
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: failover peer dhcp-failover: I move from normal to startup
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: Server starting service.
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: failover peer dhcp-failover: peer moves from normal to communications-interrupted
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: failover peer dhcp-failover: I move from startup to normal
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: balancing pool 5630299b1ad0 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-own (+/-)20
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: balanced pool 5630299b1ad0 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-misbal 31
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: failover peer dhcp-failover: peer moves from communications-interrupted to normal
Apr 04 22:29:37 altsrv3.den.skv dhcpd[5886]: failover peer dhcp-failover: Both servers normal
```

</details>

<details>
<summary>Отображение перезапуска DHCP со стороны Основного сервера</summary>

```log
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: peer dhcp-failover: disconnected
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: I move from normal to communications-interrupted
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: socket.c:1069: epoll_ctl(DEL), 11: Bad file descriptor
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: socket.c:1069: epoll_ctl(DEL), 11: Bad file descriptor
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: peer moves from normal to normal
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: I move from communications-interrupted to normal
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: failover peer dhcp-failover: Both servers normal
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: balancing pool 5584c34d0b20 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-own (+/-)20
Apr 04 22:29:37 altsrv2.den.skv dhcpd[4326]: balanced pool 5584c34d0b20 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-misbal 31
Apr 04 22:32:53 altsrv2.den.skv systemd[1]: Stopping DHCPv4 Server Daemon...
Apr 04 22:32:53 altsrv2.den.skv systemd[1]: dhcpd.service: Deactivated successfully.
Apr 04 22:32:53 altsrv2.den.skv systemd[1]: Stopped DHCPv4 Server Daemon.
Apr 04 22:32:53 altsrv2.den.skv systemd[1]: dhcpd.service: Consumed 1.978s CPU time.
Apr 04 22:32:53 altsrv2.den.skv systemd[1]: Starting DHCPv4 Server Daemon...
Apr 04 22:32:54 altsrv2.den.skv systemd[1]: Started DHCPv4 Server Daemon.
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Internet Systems Consortium DHCP Server 4.4.3-P1
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Copyright 2004-2022 Internet Systems Consortium.
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: All rights reserved.
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: For info, please visit https://www.isc.org/software/dhcp/
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Config file: /etc/dhcp/dhcpd.conf
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Database file: /var/lib/dhcp/dhcpd/state/dhcpd.leases
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: PID file: /var/run/dhcpd.pid
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Listening on LPF/ens19/36:dd:7b:0c:81:2d/192.168.100.0/24
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Sending on   LPF/ens19/36:dd:7b:0c:81:2d/192.168.100.0/24
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Sending on   Socket/fallback/fallback-net
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Wrote 0 deleted host decls to leases file.
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Wrote 0 new dynamic host decls to leases file.
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Wrote 103 leases to leases file.
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: failover peer dhcp-failover: I move from normal to startup
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: Server starting service.
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: failover peer dhcp-failover: peer moves from normal to communications-interrupted
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: failover peer dhcp-failover: I move from startup to normal
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: balancing pool 557139064b20 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-own (+/-)20
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: balanced pool 557139064b20 192.168.100.0/24  total 205  free 102  backup 102  lts 0  max-misbal 31
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: failover peer dhcp-failover: peer moves from communications-interrupted to normal
Apr 04 22:32:54 altsrv2.den.skv dhcpd[5531]: failover peer dhcp-failover: Both servers normal
```

</details>

### Для github и gitflic
```bash
exit

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

git commit -am "[upd3]ДЛЯ ВКР AD SAMBA_INTERNAL DHCP" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main

popd
```

