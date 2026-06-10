# Лабораторная работа 1 «`Установка Альт Домен`» 

![](../alt_domain.png)

## Памятка входа
```bash
# вход на bastion хост по ключу по ssh
eval $(ssh-agent) \
&& ssh-add \
~/.ssh/id_alt-domain_2026_host_ed25519

> ~/.ssh/known_hosts \
&& ssh -t -o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"su -"
```
### SSH обмен ключами (проброс ключа до altsrv1 через altwks1)
```bash
# Копируем пару ключей на промежуточный хост altwks1
> ~/.ssh/known_hosts \
&& scp \
~/.ssh/id_alt-domain_2026_host_ed25519{,.pub} \
sysadmin@172.16.100.2:~/.ssh/

# Передаем публичный ключ на altsrv1
ssh -t -o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-domain_2026_host_ed25519.pub \
sysadmin@192.168.100.11"
```

<details>
<summary>Логи передачи файлов</summary>

```log
Agent pid 16341
Identity added: /home/shoel/.ssh/id_alt-domain_2026_host_ed25519 (cours_alt-domain)
```

```log
The authenticity of host '172.16.100.2 (172.16.100.2)' can't be established.
ED25519 key fingerprint is: SHA256:cHzpYMC7ONqD/C8zAWz/WJUD+byrCOvm9Ir7DOvEspM
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '172.16.100.2' (ED25519) to the list of known hosts.
id_alt-domain_2026_host_ed25519                  100%  411    32.5KB/s   00:00    
id_alt-domain_2026_host_ed25519.pub              100%   98     7.5KB/s   00:00
```

```log
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/sysadmin/.ssh/id_alt-domain_2026_host_ed25519.pub"
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.11's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -o 'StrictHostKeyChecking=accept-new' 'sysadmin@192.168.100.11'"
and check to make sure that only the key(s) you wanted were added.

Connection to 172.16.100.2 closed.
```

</details>

### Проверка входа
```bash
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
"hostnamectl && ip -br a"
```

<details>
<summary>вывод доступа до altsrv1</summary>

```log
 Static hostname: altsrv1
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: dac3b001c8db895abaedef1a683ecf35
         Boot ID: bc37f52a2d9b4f00af087cec56ca1c69
  Virtualization: kvm
Operating System: ALT Server 11.1 (Mendelevium)
     CPE OS Name: cpe:/o:alt:server:11.1
          Kernel: Linux 6.12.27-6.12-alt1
    Architecture: x86-64
 Hardware Vendor: QEMU
  Hardware Model: Standard PC _i440FX + PIIX, 1996_
Firmware Version: 1.16.3-alt3
   Firmware Date: Tue 2014-04-01
    Firmware Age: 12y 2month 1w 2d                 
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens19            UP             192.168.100.11/24 fe80::9c6e:f5ff:fe1f:c9e7/64 
Connection to 192.168.100.11 closed.
```

</details>

## Работа по развертыванию домена
```bash
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
"su -"
```
### Смена имени под fqdn
```bash
hostnamectl \
set-hostname \
altsrv1.den.skv
```

### Устанавливаем имя NIS-домена
```bash
domainname den.skv
```
### Смена домена поиска и серверов домен контроллера

```bash
cat > /etc/net/ifaces/ens19/resolv.conf<<'EOF'
nameserver 77.88.8.8
nameserver 77.88.8.1
search den.skv
EOF
```

#### Вывод информации об интерфейсе
```bash
cat /etc/net/ifaces/ens19/*
```

<details>
<summary>ВЫВОД ОБЩИХ ПАРАМЕТРОВ интерфейса</summary>

```ini
192.168.100.11/24
default via 192.168.100.1
SYSTEMD_CONTROLLED=no
DISABLED=no
TYPE=eth
CONFIG_WIRELESS=no
BOOTPROTO=static
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=yes
NM_CONTROLLED=no
nameserver 77.88.8.8
nameserver 77.88.8.1
search den.skv
```

</details>

### Отключение IPV6
```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" \
| tee -a  /etc/sysctl.conf \
&& sysctl -p
```
#### Вывод о состоянии настроек ядра с IPV6
```bash

sysctl -a \
| grep "disable_ipv6"
```

<details>
<summary>вывод состояния ipv6</summary>

```log
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.ens19.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```

</details>

### Выключение и включения интерфейса
```bash
ifdown ens19 \
; ifup ens19 \
; systemctl restart network
```

### Проверка связи с WAN
```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```log
PING ya.ru (77.88.44.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.44.242): icmp_seq=1 ttl=53 time=13.6 ms
64 bytes from ya.ru (77.88.44.242): icmp_seq=2 ttl=53 time=13.7 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 13.633/13.685/13.737/0.052 ms
```

</details>

### Подготовка и Установка необходимых пакетов для SAMBA-DC
```bash
# Если присутствую останавливаем конфликтующие службы
systemctl stop \
smb \
nmb \
krb5kdc \
slapd \
bind \
dnsmasq

# Устанавливаем пакеты для SAMBA-DC и графическое управление его настройками
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y \
alterator-net-domain \
task-samba-dc \
alterator-datetime \
chrony

# Чистка получившихся настроек SAMBA после установки
rm -fv /etc/samba/smb.conf \
&& rm -rfv /var/{lib,cache}/samba
```

<details>
<summary>ВЫВОД чистки</summary>

```log
removed '/etc/samba/smb.conf'
removed directory '/var/lib/samba/winbindd_privileged'
removed directory '/var/lib/samba/private'
removed directory '/var/lib/samba/sysvol'
removed directory '/var/lib/samba'
removed directory '/var/cache/samba'
```

</details>

### создание каталога Sysvol для работы Домена
```bash
mkdir -pv \
/var/lib/samba/sysvol
```

<details>
<summary>Создание sysvol</summary>

```log
mkdir: created directory '/var/lib/samba'
mkdir: created directory '/var/lib/samba/sysvol'
```

</details>

### перевод chrony в режим сервера
```bash
control chrony server
```

## Настройка сервера времени Со стороны основного домен контроллера
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

# Добавляем как дополнительный сервер Будущий вторичный домен контроллер
sed -i  '/iburst/aserver altsrv2.den.skv iburst' \
/etc/chrony.conf

# Указание что хост выступает в роли сервера времени для всей локальной сети 192.168.100.0/24
sed -i 's/allow all/allow 192.168.100.0\/24/' \
/etc/chrony.conf

# Указываем возможность отвечать клиентам, если к внешнему NTP серверу нет доступа
sed -i '/\/24/alocal stratum 10' \
/etc/chrony.conf

# Запуск служб NTP
systemctl enable --now \
chronyd.service

systemctl restart \
chronyd.service

# Запуск ручной синхронизации времени
systemctl restart \
chrony-wait.service

# Проверка NTP с новым сервером
chronyc tracking
```

<details>
<summary>Вывод текущего отслеживания времени</summary>

```log
Reference ID    : 596DFB17 (ntp3.vniiftri.ru)
Stratum         : 2
Ref time (UTC)  : Wed Jun 10 21:53:57 2026
System time     : 0.000000915 seconds fast of NTP time
Last offset     : +0.000001034 seconds
RMS offset      : 0.000001034 seconds
Frequency       : 15.113 ppm slow
Residual freq   : +12.367 ppm
Skew            : 0.556 ppm
Root delay      : 0.013971020 seconds
Root dispersion : 0.000484715 seconds
Update interval : 2.0 seconds
Leap status     : Normal
```

</details>

```bash
chronyc sources
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
^* ntp3.vniiftri.ru              1   6    17    48    -20us[  -19us] +/- 7017us
```

</details>

```bash
# Проверка открытого порта для клиентов
ss -ulnp | grep :123
```
```log
UNCONN 0      0            0.0.0.0:123        0.0.0.0:*    users:(("chronyd",pid=1613,fd=6))
```
```bash
# настройки NTP на вычислительном узле 
cat /etc/chrony.conf
```
```log
server ntp3.vniiftri.ru iburst
server altsrv2.den.skv iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.100.0/24
local stratum 10
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
```

### Смена редакции лиценирования с edition_server на edition_domain
```bash
alteratorctl editions set edition_domain
```

<details>
<summary>Смена редакции</summary>

```log
* ALT Domain (edition_domain)
  ALT Server (edition_server)
free(): invalid pointer
Aborted
```

</details>

## Создание основного домен контроллера с командной строки
```bash
# –realm задает область Kerberos (LDAP), и DNS имени домена;
# –domain задает имя домена (имя рабочей группы);
# –adminpass пароль основного администратора домена;
# –server-role тип серверной роли.
# –use-rfc2307 схема Совмести UNIX систем с Active Directory 
# при использовании открытых SMB ресурсов sysvol и netlogon на контроллере домена
samba-tool domain provision \
--realm=den.skv \
--option="dns forwarder=77.88.8.8" \
--option="interfaces= lo ens19" \
--option="bind interfaces only=yes" \
--option="dns zone scavenging=yes" \
--option="allow dns updates=secure only" \
--domain den \
--server-role=dc \
--dns-backend=SAMBA_INTERNAL \
--use-rfc2307 \
--adminpass='1qaz@WSX'
```

<details>
<summary>ВЫВОД РАЗВЕРТЫВАНИЯ ДОМЕН-КОНТРОЛЕРА</summary>

```log
```

</details>