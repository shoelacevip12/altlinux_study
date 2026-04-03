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
# `AD.BASH`

## Доступ до altsrv2 сервера ssh
### Проброс имеющегося ключа
```bash
cat ~/.ssh/id_skv_VKR_vpn.pub \
| ssh -J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.12 \
'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

<details>
<summary>Успешность проброса</summary>

```log
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
Warning: Permanently added '192.168.100.12' (ED25519) to the list of known hosts.
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
sysadmin@192.168.100.12's password: 
```

</details>

## Смена имени хоста
```bash
# Вход на altsrv2
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.12 \
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
altsrv2.den.skv
```
## Устанавливаем имя NIS-домена
```bash
domainname den.skv
```
## Смена статического IP
```bash
# Смен IP адреса для DHCP сервера
sed -i 's/.12/.253/' \
/etc/net/ifaces/ens19/ipv4address

# Смена домена поиска и серверов домен контроллера
cat > /etc/net/ifaces/ens19/resolv.conf<<'EOF'
nameserver 77.88.8.8
nameserver 77.88.8.1
search den.skv
EOF
```
## Вывод информации об интерфейсе
```bash
cat /etc/net/ifaces/ens19/*
```

<details>
<summary>ВЫВОД ОБЩИХ ПАРАМЕТРОВ интерфейса</summary>

```ini
192.168.100.253/24
default via 192.168.100.1
BOOTPROTO=static
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
nameserver 77.88.8.8
nameserver 77.88.8.1
search den.skv
```

</details>

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

# Вход на altsrv2 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.253 \
"su -"

hostname
```
```log
altsrv2.den.skv
```
```bash
hostname -i
```
```log
192.168.100.253
```
```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```log
PING ya.ru (77.88.44.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.44.242): icmp_seq=1 ttl=53 time=13.8 ms
64 bytes from ya.ru (77.88.44.242): icmp_seq=2 ttl=53 time=13.9 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 13.781/13.818/13.856/0.037 ms
```

</details>

## Установка Сервера DHCP
```bash
# обновление системы и установка dhcp
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y \
dhcp-server
```
## Базовый конфиг DHCP
```bash
cat > /etc/dhcp/dhcpd.conf <<'EOF'
ddns-update-style none;

subnet 192.168.100.0 netmask 255.255.255.0 {
        option routers                  192.168.100.1;
        option subnet-mask              255.255.255.0;

        option nis-domain               "den.skv";
        option domain-name              "den.skv";
        option domain-name-servers      77.88.8.8, 77.88.8.1;

        range dynamic-bootp 192.168.100.50 192.168.100.254;
        default-lease-time 172800;
        max-lease-time 259200;
}

host altsrv1.den.skv {
  hardware ethernet ee:a8:71:80:72:45;
  fixed-address 192.168.100.254;
}

host altsrv2.den.skv {
  hardware ethernet 36:dd:7b:0c:81:2d;
  fixed-address 192.168.100.253;
}

host altsrv3.den.skv {
  hardware ethernet ae:49:e7:f8:62:2d;
  fixed-address 192.168.100.252;
}

host altsrv4.den.skv {
  hardware ethernet ce:94:fd:b4:54:40;
  fixed-address 192.168.100.251;
}
EOF
```
## Запуск DHCP с базовой настройкой
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

```bash
# ЗАпуск службы
systemctl \
enable \
--now dhcpd

# Вывод состояние службы
systemctl \
status \
dhcpd \
| grep Active
```
```log
Active: active (running) since Thu 2026-04-02 22:36:36 MSK; 4s ago
```

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

# Устанавливаем пакеты для SAMBA-DC и графическое управление его настройками
apt-get update \
&& apt-get install -y \
alterator-net-domain \
task-samba-dc \
alterator-datetime

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
--domain den \
--server-role=dc \
--dns-backend=SAMBA_INTERNAL \
--use-rfc2307 \
--adminpass='1qaz@WSX'
```

<details>
<summary>ВЫВОД РАЗВЕРТЫВАНИЯ ДОМЕН-КОНТРОЛЕРА</summary>

```log
WARNING: Using passwords on command line is insecure. Installing the setproctitle python module will hide these from shortly after program start.
INFO 2026-04-02 21:34:49,206 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2128: Looking up IPv4 addresses
INFO 2026-04-02 21:34:49,207 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2145: Looking up IPv6 addresses
WARNING 2026-04-02 21:34:49,207 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2152: No IPv6 address will be assigned
INFO 2026-04-02 21:34:49,650 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2318: Setting up share.ldb
INFO 2026-04-02 21:34:49,748 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2322: Setting up secrets.ldb
INFO 2026-04-02 21:34:49,822 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2327: Setting up the registry
INFO 2026-04-02 21:34:50,038 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2330: Setting up the privileges database
INFO 2026-04-02 21:34:50,160 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2333: Setting up idmap db
INFO 2026-04-02 21:34:50,254 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2340: Setting up SAM db
INFO 2026-04-02 21:34:50,285 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #886: Setting up sam.ldb partitions and settings
INFO 2026-04-02 21:34:50,286 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #898: Setting up sam.ldb rootDSE
INFO 2026-04-02 21:34:50,305 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1320: Pre-loading the Samba 4 and AD schema
Unable to determine the DomainSID, can not enforce uniqueness constraint on local domainSIDs

INFO 2026-04-02 21:34:50,383 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1399: Adding DomainDN: DC=den,DC=skv
INFO 2026-04-02 21:34:50,431 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1431: Adding configuration container
INFO 2026-04-02 21:34:50,477 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1446: Setting up sam.ldb schema
INFO 2026-04-02 21:34:52,696 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1466: Setting up sam.ldb configuration data
INFO 2026-04-02 21:34:52,849 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1508: Setting up display specifiers
INFO 2026-04-02 21:34:54,210 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1516: Modifying display specifiers and extended rights
INFO 2026-04-02 21:34:54,247 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1523: Adding users container
INFO 2026-04-02 21:34:54,248 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1529: Modifying users container
INFO 2026-04-02 21:34:54,249 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1532: Adding computers container
INFO 2026-04-02 21:34:54,250 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1538: Modifying computers container
INFO 2026-04-02 21:34:54,251 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1542: Setting up sam.ldb data
INFO 2026-04-02 21:34:54,379 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1573: Setting up well known security principals
INFO 2026-04-02 21:34:54,406 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1587: Setting up sam.ldb users and groups
INFO 2026-04-02 21:34:54,518 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #1595: Setting up self join
Repacking database from v1 to v2 format (first record CN=ms-WMI-int8Max,CN=Schema,CN=Configuration,DC=den,DC=skv)
Repack: re-packed 10000 records so far
Repacking database from v1 to v2 format (first record CN=nTDSDSA-Display,CN=405,CN=DisplaySpecifiers,CN=Configuration,DC=den,DC=skv)
Repacking database from v1 to v2 format (first record CN=6bcd5681-8314-11d6-977b-00c04f613221,CN=Operations,CN=DomainUpdates,CN=System,DC=den,DC=skv)
INFO 2026-04-02 21:34:56,339 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/sambadns.py #1202: Adding DNS accounts
INFO 2026-04-02 21:34:56,394 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/sambadns.py #1236: Creating CN=MicrosoftDNS,CN=System,DC=den,DC=skv
INFO 2026-04-02 21:34:56,422 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/sambadns.py #1249: Creating DomainDnsZones and ForestDnsZones partitions
INFO 2026-04-02 21:34:56,556 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/sambadns.py #1254: Populating DomainDnsZones and ForestDnsZones partitions
Repacking database from v1 to v2 format (first record DC=_kerberos._tcp,DC=den.skv,CN=MicrosoftDNS,DC=DomainDnsZones,DC=den,DC=skv)
Repacking database from v1 to v2 format (first record DC=_ldap._tcp.gc,DC=_msdcs.den.skv,CN=MicrosoftDNS,DC=ForestDnsZones,DC=den,DC=skv)
INFO 2026-04-02 21:34:56,966 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2032: Setting up sam.ldb rootDSE marking as synchronized
INFO 2026-04-02 21:34:56,977 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2037: Fixing provision GUIDs
Temporarily overriding 'dsdb:schema update allowed' setting
Applied Forest Update 11: 27a03717-5963-48fc-ba6f-69faa33e70ed
Applied Forest Update 54: 134428a8-0043-48a6-bcda-63310d9ec4dd
Applied Forest Update 79: 21ae657c-6649-43c4-bbb3-7f184fdf58c1
Applied Forest Update 80: dca8f425-baae-47cd-b424-e3f6c76ed08b
Applied Forest Update 81: a662b036-dbbe-4166-b4ba-21abea17f9cc
Applied Forest Update 82: 9d17b863-18c3-497d-9bde-45ddb95fcb65
Applied Forest Update 83: 11c39bed-4bee-45f5-b195-8da0e05b573a
Applied Forest Update 84: 4664e973-cb20-4def-b3d5-559d6fe123e0
Applied Forest Update 85: 2972d92d-a07a-44ac-9cb0-bf243356f345
Applied Forest Update 86: 09a49cb3-6c54-4b83-ab20-8370838ba149
Applied Forest Update 87: 77283e65-ce02-4dc3-8c1e-bf99b22527c2
Applied Forest Update 88: 0afb7f53-96bd-404b-a659-89e65c269420
Applied Forest Update 89: c7f717ef-fdbe-4b4b-8dfc-fa8b839fbcfa
Applied Forest Update 90: 00232167-f3a4-43c6-b503-9acb7a81b01c
Applied Forest Update 91: 73a9515b-511c-44d2-822b-444a33d3bd33
Applied Forest Update 92: e0c60003-2ed7-4fd3-8659-7655a7e79397
Applied Forest Update 93: ed0c8cca-80ab-4b6b-ac5a-59b1d317e11f
Applied Forest Update 94: b6a6c19a-afc9-476b-8994-61f5b14b3f05
Applied Forest Update 95: defc28cd-6cb6-4479-8bcb-aabfb41e9713
Applied Forest Update 96: d6bd96d4-e66b-4a38-9c6b-e976ff58c56d
Applied Forest Update 97: bb8efc40-3090-4fa2-8a3f-7cd1d380e695
Applied Forest Update 98: 2d6abe1b-4326-489e-920c-76d5337d2dc5
Applied Forest Update 99: 6b13dfb5-cecc-4fb8-b28d-0505cea24175
Applied Forest Update 100: 92e73422-c68b-46c9-b0d5-b55f9c741410
Applied Forest Update 101: c0ad80b4-8e84-4cc4-9163-2f84649bcc42
Applied Forest Update 102: 992fe1d0-6591-4f24-a163-c820fcb7f308
Applied Forest Update 103: ede85f96-7061-47bf-b11b-0c0d999595b5
Applied Forest Update 104: ee0f3271-eb51-414a-bdac-8f9ba6397a39
Applied Forest Update 105: 587d52e0-507e-440e-9d67-e6129f33bb68
Applied Forest Update 106: ce24f0f6-237e-43d6-ac04-1e918ab04aac
Applied Forest Update 107: 7f77d431-dd6a-434f-ae4d-ce82928e498f
Applied Forest Update 108: ba14e1f6-7cd1-4739-804f-57d0ea74edf4
Applied Forest Update 109: 156ffa2a-e07c-46fb-a5c4-fbd84a4e5cce
Applied Forest Update 110: 7771d7dd-2231-4470-aa74-84a6f56fc3b6
Applied Forest Update 111: 49b2ae86-839a-4ea0-81fe-9171c1b98e83
Applied Forest Update 112: 1b1de989-57ec-4e96-b933-8279a8119da4
Applied Forest Update 113: 281c63f0-2c9a-4cce-9256-a238c23c0db9
Applied Forest Update 114: 4c47881a-f15a-4f6c-9f49-2742f7a11f4b
Applied Forest Update 115: 2aea2dc6-d1d3-4f0c-9994-66c1da21de0f
Applied Forest Update 116: ae78240c-43b9-499e-ae65-2b6e0f0e202a
Applied Forest Update 117: 261b5bba-3438-4d5c-a3e9-7b871e5f57f0
Applied Forest Update 118: 3fb79c05-8ea1-438c-8c7a-81f213aa61c2
Applied Forest Update 119: 0b2be39a-d463-4c23-8290-32186759d3b1
Applied Forest Update 120: f0842b44-bc03-46a1-a860-006e8527fccd
Applied Forest Update 121: 93efec15-4dd9-4850-bc86-a1f2c8e2ebb9
Applied Forest Update 122: 9e108d96-672f-40f0-b6bd-69ee1f0b7ac4
Applied Forest Update 123: 1e269508-f862-4c4a-b01f-420d26c4ff8c
Applied Forest Update 125: e1ab17ed-5efb-4691-ad2d-0424592c5755
Applied Forest Update 126: 0e848bd4-7c70-48f2-b8fc-00fbaa82e360
Applied Forest Update 127: 016f23f7-077d-41fa-a356-de7cfdb01797
Applied Forest Update 128: 49c140db-2de3-44c2-a99a-bab2e6d2ba81
Applied Forest Update 129: e0b11c80-62c5-47f7-ad0d-3734a71b8312
Applied Forest Update 130: 2ada1a2d-b02f-4731-b4fe-59f955e24f71
Applied Forest Update 131: b83818c1-01a6-4f39-91b7-a3bb581c3ae3
Applied Forest Update 132: bbbb9db0-4009-4368-8c40-6674e980d3c3
Applied Forest Update 133: f754861c-3692-4a7b-b2c2-d0fa28ed0b0b
Applied Forest Update 134: d32f499f-3026-4af0-a5bd-13fe5a331bd2
Applied Forest Update 135: 38618886-98ee-4e42-8cf1-d9a2cd9edf8b
Applied Forest Update 136: 328092fb-16e7-4453-9ab8-7592db56e9c4
Applied Forest Update 137: 3a1c887f-df0a-489f-b3f2-2d0409095f6e
Applied Forest Update 138: 232e831f-f988-4444-8e3e-8a352e2fd411
Applied Forest Update 139: ddddcf0c-bec9-4a5a-ae86-3cfe6cc6e110
Applied Forest Update 140: a0a45aac-5550-42df-bb6a-3cc5c46b52f2
Applied Forest Update 141: 3e7645f3-3ea5-4567-b35a-87630449c70c
Applied Forest Update 142: e634067b-e2c4-4d79-b6e8-73c619324d5e
Skip Domain Update 75: 5e1574f6-55df-493e-a671-aaeffca6a100
Skip Domain Update 76: d262aae8-41f7-48ed-9f35-56bbb677573d
Skip Domain Update 77: 82112ba0-7e4c-4a44-89d9-d46c9612bf91
Applied Domain Update 78: c3c927a6-cc1d-47c0-966b-be8f9b63d991
Applied Domain Update 79: 54afcfb9-637a-4251-9f47-4d50e7021211
Applied Domain Update 80: f4728883-84dd-483c-9897-274f2ebcf11e
Applied Domain Update 81: ff4f9d27-7157-4cb0-80a9-5d6f2b14c8ff
Applied Domain Update 82: 83c53da7-427e-47a4-a07a-a324598b88f7
Applied Domain Update 83: c81fc9cc-0130-4fd1-b272-634d74818133
Applied Domain Update 84: e5f9e791-d96d-4fc9-93c9-d53e1dc439ba
Applied Domain Update 85: e6d5fd00-385d-4e65-b02d-9da3493ed850
Applied Domain Update 86: 3a6b3fbf-3168-4312-a10d-dd5b3393952d
Applied Domain Update 87: 7f950403-0ab3-47f9-9730-5d7b0269f9bd
Applied Domain Update 88: 434bb40d-dbc9-4fe7-81d4-d57229f7b080
Applied Domain Update 89: a0c238ba-9e30-4ee6-80a6-43f731e9a5cd
INFO 2026-04-02 21:34:59,365 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2432: A Kerberos configuration suitable for Samba AD has been generated at /var/lib/samba/private/krb5.conf
INFO 2026-04-02 21:34:59,366 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2434: Merge the contents of this file with your system krb5.conf or replace it with this one. Do not create a symlink!
INFO 2026-04-02 21:34:59,553 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #2102: Setting up fake yp server settings
INFO 2026-04-02 21:34:59,707 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #493: Once the above files are installed, your Samba AD server will be ready to use
INFO 2026-04-02 21:34:59,708 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #498: Server Role:           active directory domain controller
INFO 2026-04-02 21:34:59,708 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #499: Hostname:              altsrv2
INFO 2026-04-02 21:34:59,708 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #500: NetBIOS Domain:        DEN
INFO 2026-04-02 21:34:59,708 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #501: DNS Domain:            den.skv
INFO 2026-04-02 21:34:59,708 pid:4944 /usr/lib64/samba-dc/python3.9/samba/provision/__init__.py #502: DOMAIN SID:            S-1-5-21-1480690032-1578806245-2070519350
```

</details>

### Создание обратной(PTR) зоны для всей сети `192.168.100.0/24`
```bash
samba-tool dns \
zonecreate \
altsrv2.den.skv \
100.168.192.in-addr.arpa \
-U administrator
```
```log
Zone 100.168.192.in-addr.arpa created successfully
```

### Вывод информации о созданной зоне
```bash
samba-tool dns \
zoneinfo \
altsrv2.den.skv \
100.168.192.in-addr.arpa \
-U administrator
```

<details>
<summary>ВЫВОД информации о зоне</summary>

```log
Password for [DEN\administrator]:
  pszZoneName                 : 100.168.192.in-addr.arpa
  dwZoneType                  : DNS_ZONE_TYPE_PRIMARY
  fReverse                    : TRUE
  fAllowUpdate                : DNS_ZONE_UPDATE_SECURE
  fPaused                     : FALSE
  fShutdown                   : FALSE
  fAutoCreated                : FALSE
  fUseDatabase                : TRUE
  pszDataFile                 : None
  aipMasters                  : []
  fSecureSecondaries          : DNS_ZONE_SECSECURE_NO_XFER
  fNotifyLevel                : DNS_ZONE_NOTIFY_LIST_ONLY
  aipSecondaries              : []
  aipNotify                   : []
  fUseWins                    : FALSE
  fUseNbstat                  : FALSE
  fAging                      : FALSE
  dwNoRefreshInterval         : 168
  dwRefreshInterval           : 168
  dwAvailForScavengeTime      : 0
  aipScavengeServers          : []
  dwRpcStructureVersion       : 0x2
  dwForwarderTimeout          : 0
  fForwarderSlave             : 0
  aipLocalMasters             : []
  dwDpFlags                   : DNS_DP_AUTOCREATED DNS_DP_DOMAIN_DEFAULT DNS_DP_ENLISTED 
  pszDpFqdn                   : DomainDnsZones.den.skv
  pwszZoneDn                  : DC=100.168.192.in-addr.arpa,CN=MicrosoftDNS,DC=DomainDnsZones,DC=den,DC=skv
  dwLastSuccessfulSoaCheck    : 0
  dwLastSuccessfulXfr         : 0
  fQueuedForBackgroundLoad    : FALSE
  fBackgroundLoadInProgress   : FALSE
  fReadOnlyZone               : FALSE
  dwLastXfrAttempt            : 0
  dwLastXfrResult             : 0
```

</details>

## Донастройка домен-контролера
```bash
# Используемый интерфейс
ip -br a \
| awk '/253/ {print $1}'
```
```log
ens19
```
```bash
# Указание прослушивания только интерфейса локальной сети
sed -i '/7 = yes/r /dev/stdin' /etc/samba/smb.conf << "EOF"
        bind interfaces only = yes
        interfaces = lo ens19
EOF
```
### Включение очистки с интервалом обновления 30 дней
#### Включение функции очистки старых DNS записей
```bash
sed -i '/forwarder/a\        dns zone scavenging = yes' \
/etc/samba/smb.conf
```
#### Выставляем очистку с интервалом обновления 30 дней
```bash
# --refreshinterval выставляем в часах
samba-tool dns \
zoneoptions \
altsrv2.den.skv \
den.skv \
--aging=1 \
--refreshinterval=720 \
-U administrator
```
```log
Set Aging to 1
Set RefreshInterval to 720
```
```bash
cat /etc/samba/smb.conf
```

<details>
<summary>Вывод получившихся настроек SAMBA DC</summary>

```ini
# Global parameters
[global]
        dns forwarder = 77.88.8.8
        dns zone scavenging = yes
        netbios name = ALTSRV2
        realm = DEN.SKV
        server role = active directory domain controller
        workgroup = DEN
        idmap_ldb:use rfc2307 = yes
        bind interfaces only = yes
        interfaces = lo ens19

[sysvol]
        path = /var/lib/samba/sysvol
        read only = No

[netlogon]
        path = /var/lib/samba/sysvol/den.skv/scripts
        read only = No
```

</details>

## Запуск/автозапуск служб Домена
```bash
systemctl enable \
--now samba

# Заменяем ip внешних DNS на самого себя после запуска служб Домена
cat > /etc/net/ifaces/ens19/resolv.conf<<'EOF'
nameserver 127.0.0.1
search den.skv
EOF

resolvconf -a \
ens19 \
< /etc/net/ifaces/ens19/resolv.conf


# перезапускаем службу etcnet управления сетью
systemctl \
restart \
network

# перезапускам интерфейс
ifdown ens19 \
; ifup ens19
```
```log
dhcpcd-10.2.2 starting
ens19: rebinding lease of 192.168.100.253
ens19: leased 192.168.100.253 for 172800 seconds
ens19: adding route to 192.168.100.0/24
ens19: adding default route via 192.168.100.1
```
```bash
# проверка работы через кеширующий DNS
cat /etc/resolv.conf
```
```ini
# Generated by resolvconf
# Do not edit manually, use
# /etc/net/ifaces/<interface>/resolv.conf instead.
domain den.skv
nameserver 127.0.0.1
```
## Обновление DHCP настроек
```bash
# Для сервиса DHCP поменяем внешние DNS на локальные
sed -i 's/77.88.8.8, 77.88.8.1/192.168.100.253, 192.168.100.252/' \
/etc/dhcp/dhcpd.conf

# проверка конфига
dhcpd -t
```

<details>
<summary>Вывод о работоспособности конфига</summary>

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

```bash
# Перезапуск службы
systemctl \
restart \
dhcpd
```

## Проверка поднятого домена
```bash
systemctl \
status \
samba
```


<details>
<summary>ВЫВОД СОСТОЯНИЯ ДОМЕН-КОНТРОЛЕРА</summary>

```log
● samba.service - Samba AD Daemon
     Loaded: loaded (/lib/systemd/system/samba.service; enabled; vendor preset: disabled)
     Active: active (running) since Thu 2026-04-02 22:46:05 MSK; 10min ago
       Docs: man:samba(8)
             man:samba(7)
             man:smb.conf(5)
   Main PID: 4993 (samba)
     Status: "samba: ready to serve connections..."
      Tasks: 59 (limit: 4680)
     Memory: 180.8M
        CPU: 10.223s
     CGroup: /system.slice/samba.service
             ├─ 4993 /usr/sbin/samba --foreground --no-process-group
             ├─ 4994 /usr/sbin/samba --foreground --no-process-group
             ├─ 4995 /usr/sbin/samba --foreground --no-process-group
             ├─ 4996 /usr/sbin/samba --foreground --no-process-group
             ├─ 4997 /usr/sbin/samba --foreground --no-process-group
             ├─ 4998 /usr/sbin/samba --foreground --no-process-group
             ├─ 4999 /usr/sbin/smbd -D "--option=server role check:inhibit=yes" --foreground ""
             ├─ 5000 /usr/sbin/samba --foreground --no-process-group
             ├─ 5001 /usr/sbin/samba --foreground --no-process-group
             ├─ 5002 /usr/sbin/samba --foreground --no-process-group
             ├─ 5003 /usr/sbin/samba --foreground --no-process-group
             ├─ 5004 /usr/sbin/samba --foreground --no-process-group
             ├─ 5005 /usr/sbin/samba --foreground --no-process-group
             ├─ 5006 /usr/sbin/samba --foreground --no-process-group
             ├─ 5007 /usr/sbin/samba --foreground --no-process-group
             ├─ 5008 /usr/sbin/samba --foreground --no-process-group
             ├─ 5009 /usr/sbin/samba --foreground --no-process-group
             ├─ 5010 /usr/sbin/samba --foreground --no-process-group
             ├─ 5011 /usr/sbin/samba --foreground --no-process-group
             ├─ 5012 /usr/sbin/samba --foreground --no-process-group
             ├─ 5013 /usr/sbin/samba --foreground --no-process-group
             ├─ 5014 /usr/sbin/samba --foreground --no-process-group
             ├─ 5015 /usr/sbin/samba --foreground --no-process-group
             ├─ 5016 /usr/sbin/samba --foreground --no-process-group
             ├─ 5017 /usr/sbin/samba --foreground --no-process-group
             ├─ 5018 /usr/sbin/samba --foreground --no-process-group
             ├─ 5019 /usr/sbin/samba --foreground --no-process-group
             ├─ 5020 /usr/sbin/samba --foreground --no-process-group
             ├─ 5021 /usr/sbin/samba --foreground --no-process-group
             ├─ 5022 /usr/sbin/samba --foreground --no-process-group
             ├─ 5023 /usr/sbin/samba --foreground --no-process-group
             ├─ 5024 /usr/sbin/samba --foreground --no-process-group
             ├─ 5025 /usr/sbin/samba --foreground --no-process-group
             ├─ 5026 /usr/sbin/samba --foreground --no-process-group
             ├─ 5027 /usr/sbin/samba --foreground --no-process-group
             ├─ 5028 /usr/sbin/samba --foreground --no-process-group
             ├─ 5029 /usr/sbin/samba --foreground --no-process-group
             ├─ 5030 /usr/sbin/samba --foreground --no-process-group
             ├─ 5031 /usr/sbin/winbindd -D "--option=server role check:inhibit=yes" --foreground ""
             ├─ 5033 /usr/sbin/samba --foreground --no-process-group
             ├─ 5034 /usr/sbin/samba --foreground --no-process-group
             ├─ 5035 /usr/sbin/samba --foreground --no-process-group
             ├─ 5036 /usr/sbin/samba --foreground --no-process-group
             ├─ 5037 /usr/sbin/samba --foreground --no-process-group
             ├─ 5038 /usr/sbin/samba --foreground --no-process-group
             ├─ 5039 /usr/sbin/samba --foreground --no-process-group
             ├─ 5040 /usr/sbin/samba --foreground --no-process-group
             ├─ 5046 /usr/sbin/smbd -D "--option=server role check:inhibit=yes" --foreground ""
             ├─ 5047 /usr/sbin/smbd -D "--option=server role check:inhibit=yes" --foreground ""
             ├─ 5048 /usr/sbin/winbindd -D "--option=server role check:inhibit=yes" --foreground ""
             ├─ 5049 /usr/sbin/winbindd -D "--option=server role check:inhibit=yes" --foreground ""
             ├─ 5050 /usr/sbin/samba --foreground --no-process-group
             ├─ 5051 /usr/sbin/samba --foreground --no-process-group
             ├─ 5052 /usr/sbin/samba --foreground --no-process-group
             ├─ 5053 /usr/sbin/samba --foreground --no-process-group
             ├─ 5054 /usr/sbin/samba --foreground --no-process-group
             ├─ 5055 /usr/sbin/samba --foreground --no-process-group
             ├─ 5056 /usr/sbin/samba --foreground --no-process-group
             └─ 5057 /usr/sbin/samba --foreground --no-process-group

Apr 02 22:46:09 altsrv2.den.skv samba[5038]: [2026/04/02 22:46:09.766332,  0] ../../lib/util/util_runcmd.c:355(samba_runcmd_io_handler)
Apr 02 22:46:09 altsrv2.den.skv samba[5038]:   /usr/sbin/samba_dnsupdate: ERROR(runtime): Record already exists; record could not be added. >
Apr 02 22:46:09 altsrv2.den.skv samba[5038]: [2026/04/02 22:46:09.828900,  0] ../../lib/util/util_runcmd.c:355(samba_runcmd_io_handler)
Apr 02 22:46:09 altsrv2.den.skv samba[5038]:   /usr/sbin/samba_dnsupdate: ERROR(runtime): Record already exists; record could not be added. >
Apr 02 22:46:09 altsrv2.den.skv samba[5038]: [2026/04/02 22:46:09.887496,  0] ../../lib/util/util_runcmd.c:355(samba_runcmd_io_handler)
Apr 02 22:46:09 altsrv2.den.skv samba[5038]:   /usr/sbin/samba_dnsupdate: ERROR(runtime): Record already exists; record could not be added. >
Apr 02 22:46:09 altsrv2.den.skv samba[5038]: [2026/04/02 22:46:09.943725,  0] ../../lib/util/util_runcmd.c:355(samba_runcmd_io_handler)
Apr 02 22:46:09 altsrv2.den.skv samba[5038]:   /usr/sbin/samba_dnsupdate: ERROR(runtime): Record already exists; record could not be added. >
Apr 02 22:46:09 altsrv2.den.skv samba[5038]: [2026/04/02 22:46:09.998434,  0] ../../source4/dsdb/dns/dns_update.c:85(dnsupdate_nameupdate_do>
Apr 02 22:46:09 altsrv2.den.skv samba[5038]:   dnsupdate_nameupdate_done: Failed DNS update with exit code 29
```
</details>

```bash
# Базовая информация
samba-tool domain \
info \
127.0.0.1
```

<details>
<summary>ВЫВОД БАЗОВОЙ ИНФОРМАЦИИ О ДОМЕН-КОНТРОЛЕРЕ</summary>

```
Forest           : den.skv
Domain           : den.skv
Netbios domain   : DEN
DC name          : altsrv2.den.skv
DC netbios name  : ALTSRV2
Server site      : Default-First-Site-Name
Client site      : Default-First-Site-Name
```
</details>

```bash
# Настройки конфига SAMBA
cat /etc/samba/smb.conf
```

<details>
<summary>ВЫВОД получившихся настроек SAMBA DC</summary>

```ini
</details>
# Global parameters
[global]
        dns forwarder = 77.88.8.8
        dns zone scavenging = yes
        netbios name = ALTSRV2
        realm = DEN.SKV
        server role = active directory domain controller
        workgroup = DEN
        idmap_ldb:use rfc2307 = yes
        bind interfaces only = yes
        interfaces = lo ens19

[sysvol]
        path = /var/lib/samba/sysvol
        read only = No

[netlogon]
        path = /var/lib/samba/sysvol/den.skv/scripts
        read only = No
```
</details>

```bash
# Вывод доступных Сетевых папок\Служб текущего хоста
smbclient -L localhost \
-U Administrator
```

<details>
<summary>Доступные сетевые папки домен-контролера</summary>

```bash
Password for [DEN\Administrator]:

        Sharename       Type      Comment
        ---------       ----      -------
        sysvol          Disk      
        netlogon        Disk      
        IPC$            IPC       IPC Service (Samba 4.19.9-alt9)
SMB1 disabled -- no workgroup available
```

</details>

```bash
# текущие настройки resolvconf
resolvconf -l
```

<details>
<summary>текущие настройки resolvconf</summary>

```log
# resolv.conf from ens19
nameserver 127.0.0.1
search den.skv
```

</details>

```bash
# Первый пинг адреса(без кеша) до внешнего сайта
ping pub.ru -c 2
```

<details>
<summary>Первый пинг DNS-адреса (без кеша)</summary>

```log
PING pub.ru (62.122.170.171) 56(84) bytes of data.
64 bytes from 62.122.170.171.serverel.net (62.122.170.171): icmp_seq=1 ttl=53 time=40.1 ms
64 bytes from 62.122.170.171.serverel.net (62.122.170.171): icmp_seq=2 ttl=53 time=40.3 ms

--- pub.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 40.117/40.214/40.312/0.097 ms
```

</details>

```bash
# Резолв хоста за именем домена
host den.skv
```
```log
den.skv has address 192.168.100.253
```

```bash
# Резолв хоста по fqdn
host altsrv2.den.skv
```
```log
altsrv2.den.skv has address 192.168.100.253
```
```bash
# Резолв DNS-сервер записи домена
host -t NS den.skv
```
```log
den.skv name server altsrv2.den.skv.
```
```bash
# Резолв записи Службы kerberos в домене den.skv
host -t SRV _kerberos._udp.den.skv
```
```log
_kerberos._udp.den.skv has SRV record 0 100 88 altsrv2.den.skv.
```
```bash
# Резолв записи Службы ldap в домене den.skv
host -t SRV _ldap._tcp.den.skv
```
```log
_ldap._tcp.den.skv has SRV record 0 100 389 altsrv2.den.skv
```
### Локальная Проверка работы Kerberos
```bash
# backup стандартного конфига /etc/krb5.conf
cp /etc/krb5.conf{,.bak}


# Заменяем настройки Kerberos для клиентского обращение к серверу созданные доменом
cat /var/lib/samba/private/krb5.conf \
| tee /etc/krb5.conf
```
```ini
[libdefaults]
        default_realm = DEN.SKV
        dns_lookup_realm = false
        dns_lookup_kdc = true

[realms]
DEN.SKV = {
        default_domain = den.skv
}

[domain_realm]
        altsrv2 = DEN.SKV
```

```bash
# Вход под обычным локальным пользователем хоста
su - sysadmin

# проверка имеющихся белетов kerberos
klist
```
```log
klist: No credentials cache found (filename: /tmp/krb5cc_500)
```
```bash
# удаление имеющихся ключей kerberos (если есть)
kdestroy
```
```bash
# Получение белета kerberos
kinit Administrator
```
```log
Password for Administrator@DEN.SKV: 
Warning: Your password will expire in 41 days on Thu May 14 22:45:25 2026
```
```bash
# Проверка получения белета
klist
```

<details>
<summary>Информация о билете</summary>

```log
Ticket cache: FILE:/tmp/krb5cc_500
Default principal: Administrator@DEN.SKV

Valid starting     Expires            Service principal
04/02/26 23:24:31  04/03/26 09:24:31  krbtgt/DEN.SKV@DEN.SKV
        renew until 04/03/26 23:24:27
```

</details>

## Настройка сервера времени Со стороны основного домен контроллера
```bash
# обновление системы и установка dhcp
apt-get update \
&& apt-get install -y \
chrony

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
sed -i  '/iburst/aserver altsrv3.den.skv iburst' \
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
Ref time (UTC)  : Fri Apr 03 08:44:17 2026
System time     : 0.000140978 seconds slow of NTP time
Last offset     : -0.000155140 seconds
RMS offset      : 0.002252836 seconds
Frequency       : 18.016 ppm slow
Residual freq   : -0.067 ppm
Skew            : 4.530 ppm
Root delay      : 0.014275064 seconds
Root dispersion : 0.000138944 seconds
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
^* ntp3.vniiftri.ru              1   6   377    50   -197us[ -282us] +/- 7579us
```

</details>

```bash
# Проверка открытого порта для клиентов
ss -ulnp | grep :123
```
```log
UNCONN 0      0              0.0.0.0:123       0.0.0.0:*    users:(("chronyd",pid=3717,fd=7))
```
```bash
# настройки NTP на вычислительном узле 
cat /etc/chrony.conf
```
```log
server ntp3.vniiftri.ru iburst
server altsrv3.den.skv iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.100.0/24
local stratum 10
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
```

## Создание первых пользователей AD

```bash
# под суперпользователем
su -
```
### Создание пользователей
```bash
samba-tool user create \
smaba_u1 \
--given-name='Василий Иванович Чапаев' \
--mail-address='chapay_vi@den.skv'
```
```log
New Password: 
Retype Password: 
User 'smaba_u1' added successfully
```
```bash
samba-tool user create \
smaba_u2 \
--given-name='Моледцев Владимир Александрович' \
--mail-address='syn_polka@den.skv'
```
```log
New Password: 
Retype Password: 
User 'smaba_u2' added successfully
```
```bash
samba-tool user create \
smaba_u3 \
--given-name='Колкин Павел Сергеевич' \
--mail-address='garaj@den.skv'
```
```log
New Password: 
Retype Password: 
User 'smaba_u3' added successfully
```
### Включение пользователей
```bash
# Просмотр списка имеющихся пользователей
samba-tool user \
list
```
```log
smaba_u3
Guest
smaba_u1
smaba_u2
krbtgt
Administrator
```
```bash
# Подробный просмотр пользователя LDAP 
samba-tool user \
show \
smaba_u2
```

<details>
<summary>Вывод информации о пользователе домена</summary>

```bash
dn: CN=Моледцев Владимир Александрович,CN=Users,DC=den,DC=skv
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
cn: Моледцев Владимир Александрович
givenName: Моледцев Владимир Александрович
instanceType: 4
whenCreated: 20260403085428.0Z
whenChanged: 20260403085428.0Z
displayName: Моледцев Владимир Александрович
uSNCreated: 4281
name: Моледцев Владимир Александрович
objectGUID: 4c7413ca-ca4a-4a1f-8f27-9383d87fdfde
badPwdCount: 0
codePage: 0
countryCode: 0
badPasswordTime: 0
lastLogoff: 0
lastLogon: 0
primaryGroupID: 513
objectSid: S-1-5-21-4113027746-331116429-4112936127-1104
accountExpires: 9223372036854775807
logonCount: 0
sAMAccountName: smaba_u2
sAMAccountType: 805306368
userPrincipalName: smaba_u2@den.skv
objectCategory: CN=Person,CN=Schema,CN=Configuration,DC=den,DC=skv
mail: syn_polka@den.skv
pwdLastSet: 134196800686232510
userAccountControl: 512
uSNChanged: 4283
distinguishedName: CN=Моледцев Владимир Александрович,CN=Users,DC=den,DC=skv
```

</details>

```bash
# Разблокировка созданных учетных записей по шаблону EXP
for n in {1..3}; do \
samba-tool user \
setexpiry smaba_u$n \
--noexpiry; done
```
```log
Expiry for user 'smaba_u1' disabled.
Expiry for user 'smaba_u2' disabled.
Expiry for user 'smaba_u3' disabled.
```

## Создание групп пользователей

```bash
# Создание групп
samba-tool group add \
'Вымышленные_герои'
```
```log
Added group Вымышленные_герои
```
```bash
# Списки имеющихся групп
samba-tool group \
list 
```

<details>
<summary>Список групп домена</summary>

```log
Protected Users
Account Operators
Distributed COM Users
Replicator
Remote Desktop Users
Terminal Server License Servers
Read-only Domain Controllers
Domain Computers
Backup Operators
Performance Log Users
Windows Authorization Access Group
Domain Controllers
Administrators
Cert Publishers
Domain Users
Pre-Windows 2000 Compatible Access
Denied RODC Password Replication Group
Cryptographic Operators
Incoming Forest Trust Builders
RAS and IAS Servers
Domain Guests
Certificate Service DCOM Access
IIS_IUSRS
DnsUpdateProxy
Network Configuration Operators
Вымышленные_герои
Domain Admins
Enterprise Read-only Domain Controllers
Print Operators
Schema Admins
Event Log Readers
Group Policy Creator Owners
Enterprise Admins
Server Operators
Performance Monitor Users
Users
Allowed RODC Password Replication Group
DnsAdmins
Guests
```

</details>

### Добавление пользователей в группы
```bash
# Добавление пользователей в группы
for n in {1..3}; do \
samba-tool group addmembers \
'Вымышленные_герои' \
smaba_u$n ; done
```
```log
Added members to group Вымышленные_герои
Added members to group Вымышленные_герои
Added members to group Вымышленные_герои
```
```bash
samba-tool group addmembers \
'Domain Admins' \
smaba_u1
```
```log
Added members to group Domain Admins
```
```bash
# Проверка членства в группах
for g in \
{'Вымышленные_герои','Domain Users','Domain Admins'}; do \
echo "---$g---"
samba-tool group listmembers "$g"; done
```

<details>
<summary>Вывод списка пользователей групп</summary>

```log
---Вымышленные_герои---
smaba_u3
smaba_u2
smaba_u1
---Domain Users---
smaba_u3
smaba_u2
krbtgt
Administrator
smaba_u1
---Domain Admins---
Administrator
smaba_u1
```

</details>

## Настройка DHCP-сервера для обновления DNS-записей
### Создание пользователя, от имени которого будут производится обновления DNS-записей
```bash
# random-password подразумевает что это будет служебный пользователь
## Для дальнейшего взаимодействия пользователем будут через Kerberos, а не через пароль(знать нам его не обязательно)
samba-tool user \
create \
dhcpduser \
--description="Пользователь обновления DNS через DHCP-сервер" \
--random-password
```
```log
User 'dhcpduser' added successfully
```
### Добавление пользователя для работы с DNS в соответствующую группу с правами
```bash
samba-tool group \
addmembers \
'DnsAdmins' \
dhcpduser
```
```log
Added members to group DnsAdmins
```
### Установить срок действия пароля пользователя бессрочным (включить пользователя)
```bash
samba-tool user \
setexpiry \
dhcpduser \
--noexpiry
```
### Экспорт файла keytab для пользователя для аутентификации через Kerberos в AD
```bash
samba-tool domain \
exportkeytab \
--principal=dhcpduser@DEN.SKV \
/etc/dhcp/dhcpduser.keytab
```
```log
Export one principal to /etc/dhcp/dhcpduser.keytab
```
```bash
# проверка созданного файла
file /etc/dhcp/dhcpduser.keytab
```
```log
/etc/dhcp/dhcpduser.keytab: Kerberos Keytab file, realm=DEN.SKV, principal=dhcpduser/, type=92623, date=Wed Dec 15 17:27:28 2049, kvno=18
```

### Смена Владельца к файлу Kerberos
```bash
chown -v dhcpd:dhcp \
/etc/dhcp/dhcpduser.keytab
```
```log
changed ownership of '/etc/dhcp/dhcpduser.keytab' from root:root to dhcpd:dhcp
```
### Ограничение прав на работу с файлом Kerberos
```bash
chmod -v 400 \
/etc/dhcp/dhcpduser.keytab
```
```
mode of '/etc/dhcp/dhcpduser.keytab' changed from 0600 (rw-------) to 0400 (r--------)
```

## Скрипт выполнения действий по обновлению DNS записей

<details>
<summary>СКРИПТ ОБНОВЛЕНИЯ DNS</summary>

```bash
cat > /usr/local/bin/dhcp-dyndns.sh <<'EOT'
#!/bin/bash
#
# This script is for secure DDNS updates on Samba,
# it can also add the 'macAddress' to the Computers object.
#
# Version: 0.9.6
#

##########################################################################
#                                                                        #
#    You can optionally add the 'macAddress' to the Computers object.    #
#    Add 'dhcpduser' to the 'Domain Admins' group if used                #
#    Change the next line to 'yes' to make this happen                   #
Add_macAddress='no'
#                                                                        #
##########################################################################

keytab=/etc/dhcp/dhcpduser.keytab

usage()
{
  cat <<-EOF
  USAGE:
    $(basename "$0") add ip-address dhcid|mac-address hostname
    $(basename "$0") delete ip-address dhcid|mac-address
EOF
}

_KERBEROS()
{
  # get current time as a number
  test=$(date +%d'-'%m'-'%y' '%H':'%M':'%S)
  # Note: there have been problems with this
  # check that 'date' returns something like

  # Check for valid kerberos ticket
  #logger "${test} [dyndns] : Running check for valid kerberos ticket"
  klist -c "${KRB5CCNAME}" -s
  ret="$?"
  if [ $ret -ne 0 ]
  then
    logger "${test} [dyndns] : Getting new ticket, old one has expired"
    kinit -F -k -t $keytab "${SETPRINCIPAL}"
    ret="$?"
    if [ $ret -ne 0 ]
    then
      logger "${test} [dyndns] : dhcpd kinit for dynamic DNS failed"
      exit 1
    fi
  fi
}

rev_zone_info()
{
  local RevZone="$1"
  local IP="$2"
  local rzoneip
  rzoneip="${RevZone%.in-addr.arpa}"
  local rzonenum
  rzonenum=$(echo "$rzoneip" |  tr '.' '\n')
  declare -a words
  for n in $rzonenum
  do
    words+=("$n")
  done
  local numwords="${#words[@]}"

  unset ZoneIP
  unset RZIP
  unset IP2add

  case "$numwords" in
    1)
      # single ip rev zone '192'
      ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1}')
      RZIP="${rzoneip}"
      IP2add=$(echo "${IP}" | awk -F '.' '{print $4"."$3"."$2}')
      ;;
    2)
      # double ip rev zone '168.192'
      ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1"."$2}')
      RZIP=$(echo "${rzoneip}" | awk -F '.' '{print $2"."$1}')
      IP2add=$(echo "${IP}" | awk -F '.' '{print $4"."$3}')
      ;;
    3)
      # triple ip rev zone '0.168.192'
      ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1"."$2"."$3}')
      RZIP=$(echo "${rzoneip}" | awk -F '.' '{print $3"."$2"."$1}')
      IP2add=$(echo "${IP}" | awk -F '.' '{print $4}')
      ;;
    *)
      # should never happen
      exit 1
      ;;
  esac
}

BINDIR=$(samba -b | grep 'BINDIR' | grep -v 'SBINDIR' | awk '{print $NF}')
[[ -z $BINDIR ]] && printf "Cannot find the 'samba' binary, is it installed ?\\nOr is your path set correctly ?\\n"
WBINFO="$BINDIR/wbinfo"

SAMBATOOL=$(command -v samba-tool)
[[ -z $SAMBATOOL ]] && printf "Cannot find the 'samba-tool' binary, is it installed ?\\nOr is your path set correctly ?\\n"

MINVER=$($SAMBATOOL -V | grep -o '[0-9]*' | tr '\n' ' ' | awk '{print $2}')
if [ "$MINVER" -gt '14' ]
then
  KTYPE="--use-kerberos=required"
else
  KTYPE="-k yes"
fi

# DHCP Server hostname
Server=$(hostname -s)

# DNS domain
domain=$(hostname -d)
if [ -z "${domain}" ]
then
  logger "Cannot obtain domain name, is DNS set up correctly?"
  logger "Cannot continue... Exiting."
  exit 1
fi

# Samba realm
REALM="${domain^^}"

# krbcc ticket cache
export KRB5CCNAME="/tmp/dhcp-dyndns.cc"

# Kerberos principal
SETPRINCIPAL="dhcpduser@${REALM}"
# Kerberos keytab as above
# krbcc ticket cache : /tmp/dhcp-dyndns.cc
TESTUSER="$($WBINFO -u | grep 'dhcpduser')"
if [ -z "${TESTUSER}" ]
then
  logger "No AD dhcp user exists, need to create it first.. exiting."
  logger "you can do this by typing the following commands"
  logger "kinit Administrator@${REALM}"
  logger "$SAMBATOOL user create dhcpduser --random-password --description='Unprivileged Пользователь обновления DNS через DHCP-сервер'"
  logger "$SAMBATOOL user setexpiry dhcpduser --noexpiry"
  logger "$SAMBATOOL group addmembers DnsAdmins dhcpduser"
  exit 1
fi

# Check for Kerberos keytab
if [ ! -f "$keytab" ]
then
  logger "Required keytab $keytab not found, it needs to be created."
  logger "Use the following commands as root"
  logger "$SAMBATOOL domain exportkeytab --principal=${SETPRINCIPAL} $keytab"
  logger "chown dhcpd:dhcp $keytab"
  logger "Replace 'dhcpd:dhcp' with the user & group that dhcpd runs as on your distro"
  logger "chmod 400 $keytab"
  exit 1
fi

# Variables supplied by dhcpd.conf
action="$1"
ip="$2"
DHCID="$3"
name="${4%%.*}"

# Exit if no ip address
if [ -z "${ip}" ]
then
  usage
  exit 1
fi

# Exit if no computer name supplied, unless the action is 'delete'
if [ -z "${name}" ]
then
  if [ "${action}" = "delete" ]
  then
    name=$(host -t PTR "${ip}" | awk '{print $NF}' | awk -F '.' '{print $1}')
  else
    usage
    exit 1
  fi
fi

# exit if name contains a space
case ${name} in
  *\ * )
    logger "Invalid hostname '${name}' ...Exiting"
    exit
    ;;
esac

# if you want computers with a hostname that starts with 'dhcp' in AD
# comment the following block of code.
if [[ $name == dhcp* ]]
then
  logger "not updating DNS record in AD, invalid name"
  exit 0
fi

## update ##
case "${action}" in
  add)
    _KERBEROS
    count=0
    # does host have an existing 'A' record ?
    mapfile -t A_REC < <($SAMBATOOL dns query "${Server}" "${domain}" "${name}" A "$KTYPE" 2>/dev/null | grep 'A:' | awk '{print $2}')
    if [ "${#A_REC[@]}" -eq 0 ]
    then
      # no A record to delete
      result1=0
      $SAMBATOOL dns add "${Server}" "${domain}" "${name}" A "${ip}" "$KTYPE"
      result2="$?"
    elif [ "${#A_REC[@]}" -gt 1 ]
    then
      for i in "${A_REC[@]}"
      do
        $SAMBATOOL dns delete "${Server}" "${domain}" "${name}" A "${i}" "$KTYPE"
      done
      # all A records deleted
      result1=0
      $SAMBATOOL dns add "${Server}" "${domain}" "${name}" A "${ip}" "$KTYPE"
      result2="$?"
    elif [ "${#A_REC[@]}" -eq 1 ]
    then
      # turn array into a variable
      VAR_A_REC="${A_REC[*]}"
      if [ "$VAR_A_REC" = "${ip}" ]
      then
        # Correct A record exists, do nothing
        logger "Correct 'A' record exists, not updating."
        result1=0
        result2=0
        count=$((count+1))
      elif [ "$VAR_A_REC" != "${ip}" ]
      then
        # Wrong A record exists
        logger "'A' record changed, updating record."
        $SAMBATOOL dns delete "${Server}" "${domain}" "${name}" A "${VAR_A_REC}" "$KTYPE"
        result1="$?"
        $SAMBATOOL dns add "${Server}" "${domain}" "${name}" A "${ip}" "$KTYPE"
        result2="$?"
      fi
    fi

    # get existing reverse zones (if any)
    ReverseZones=$($SAMBATOOL dns zonelist "${Server}" "$KTYPE" --reverse | grep 'pszZoneName' | awk '{print $NF}')
    if [ -z "$ReverseZones" ]; then
      logger "No reverse zone found, not updating"
      result3='0'
      result4='0'
      count=$((count+1))
    else
      for revzone in $ReverseZones
      do
        rev_zone_info "$revzone" "${ip}"
        if [[ ${ip} = $ZoneIP* ]] && [ "$ZoneIP" = "$RZIP" ]
        then
          # does host have an existing 'PTR' record ?
          PTR_REC=$($SAMBATOOL dns query "${Server}" "${revzone}" "${IP2add}" PTR "$KTYPE" 2>/dev/null | grep 'PTR:' | awk '{print $2}' | awk -F '.' '{print $1}')
          if [[ -z $PTR_REC ]]
          then
            # no PTR record to delete
            result3=0
            $SAMBATOOL dns add "${Server}" "${revzone}" "${IP2add}" PTR "${name}"."${domain}" "$KTYPE"
            result4="$?"
            break
          elif [ "$PTR_REC" = "${name}" ]
          then
            # Correct PTR record exists, do nothing
            logger "Correct 'PTR' record exists, not updating."
            result3=0
            result4=0
            count=$((count+1))
            break
          elif [ "$PTR_REC" != "${name}" ]
          then
            # Wrong PTR record exists
            # points to wrong host
            logger "'PTR' record changed, updating record."
            $SAMBATOOL dns delete "${Server}" "${revzone}" "${IP2add}" PTR "${PTR_REC}"."${domain}" "$KTYPE"
            result3="$?"
            $SAMBATOOL dns add "${Server}" "${revzone}" "${IP2add}" PTR "${name}"."${domain}" "$KTYPE"
            result4="$?"
            break
          fi
        else
          continue
        fi
      done
    fi
    ;;
  delete)
    _KERBEROS

    count=0
    $SAMBATOOL dns delete "${Server}" "${domain}" "${name}" A "${ip}" "$KTYPE"
    result1="$?"
    # get existing reverse zones (if any)
    ReverseZones=$($SAMBATOOL dns zonelist "${Server}" --reverse "$KTYPE" | grep 'pszZoneName' | awk '{print $NF}')
    if [ -z "$ReverseZones" ]
    then
      logger "No reverse zone found, not updating"
      result2='0'
      count=$((count+1))
    else
      for revzone in $ReverseZones
      do
        rev_zone_info "$revzone" "${ip}"
        if [[ ${ip} = $ZoneIP* ]] && [ "$ZoneIP" = "$RZIP" ]
        then
          host -t PTR "${ip}" > /dev/null 2>&1
          ret="$?"
          if [ $ret -eq 0 ]
          then
            $SAMBATOOL dns delete "${Server}" "${revzone}" "${IP2add}" PTR "${name}"."${domain}" "$KTYPE"
            result2="$?"
          else
            result2='0'
            count=$((count+1))
          fi
          break
        else
          continue
        fi
      done
    fi
    result3='0'
    result4='0'
    ;;
	*)
    logger "Invalid action specified"
    exit 103
  ;;
esac

result="${result1}:${result2}:${result3}:${result4}"

if [ "$count" -eq 0 ]
then
  if [ "${result}" != "0:0:0:0" ]
  then
    logger "DHCP-DNS $action failed: ${result}"
    exit 1
  else
    logger "DHCP-DNS $action succeeded"
  fi
fi

if [ "$Add_macAddress" != 'no' ]
then
  if [ -n "$DHCID" ]
  then
    Computer_Object=$(ldbsearch "$KTYPE" -H ldap://"$Server" "(&(objectclass=computer)(objectclass=ieee802Device)(cn=$name))" | grep -v '#' | grep -v 'ref:')
    if [ -z "$Computer_Object" ]
    then
      # Computer object not found with the 'ieee802Device' objectclass, does the computer actually exist, it should.
      Computer_Object=$(ldbsearch "$KTYPE" -H ldap://"$Server" "(&(objectclass=computer)(cn=$name))" | grep -v '#' | grep -v 'ref:')
      if [ -z "$Computer_Object" ]
      then
        logger "Computer '$name' not found. Exiting."
        exit 68
      else
        DN=$(echo "$Computer_Object" | grep 'dn:')
        objldif="$DN
changetype: modify
add: objectclass
objectclass: ieee802Device"

        attrldif="$DN
changetype: modify
add: macAddress
macAddress: $DHCID"

        # add the ldif
        echo "$objldif" | ldbmodify "$KTYPE" -H ldap://"$Server"
        ret="$?"
        if [ $ret -ne 0 ]
        then
          logger "Error modifying Computer objectclass $name in AD."
          exit "${ret}"
        fi
        sleep 2
        echo "$attrldif" | ldbmodify "$KTYPE" -H ldap://"$Server"
        ret="$?"
        if [ "$ret" -ne 0 ]; then
          logger "Error modifying Computer attribute $name in AD."
          exit "${ret}"
        fi
        unset objldif
        unset attrldif
        logger "Successfully modified Computer $name in AD"
      fi
  else
    DN=$(echo "$Computer_Object" | grep 'dn:')
    attrldif="$DN
changetype: modify
replace: macAddress
macAddress: $DHCID"

    echo "$attrldif" | ldbmodify "$KTYPE" -H ldap://"$Server"
    ret="$?"
    if [ "$ret" -ne 0 ]
    then
      logger "Error modifying Computer attribute $name in AD."
      exit "${ret}"
    fi
      unset attrldif
      logger "Successfully modified Computer $name in AD"
    fi
  fi
fi

exit 0
EOT
```

</details>

```bash
# Делаем скрипт исполняемым и доступным
chmod 755 /usr/local/bin/dhcp-dyndns.sh
```

## Изменение конфигурации DHCP
### Резервная копия рабочего файла конфигурации dhcp
```bash
cp -v /etc/dhcp/dhcpd.conf{,.bak}
```
```log
'/etc/dhcp/dhcpd.conf' -> '/etc/dhcp/dhcpd.conf.bak'
```
### Замена конфигурации DHCP
```bash
cat > /etc/dhcp/dhcpd.conf <<'EOF'
authoritative;
ddns-update-style none;

subnet 192.168.100.0 netmask 255.255.255.0 {
        option broadcast-address        192.168.100.255;
        option time-offset              0;
        option routers                  192.168.100.1;
        option subnet-mask              255.255.255.0;

        option nis-domain               "den.skv";
        option domain-name              "den.skv";
        option domain-name-servers      192.168.100.253, 192.168.100.252;
        option ntp-servers              192.168.100.253, 192.168.100.252;

        range dynamic-bootp 192.168.100.50 192.168.100.254;
        default-lease-time 172800;
        max-lease-time 259200;
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
  fixed-address 192.168.100.254;
}

host altsrv2.den.skv {
  hardware ethernet 36:dd:7b:0c:81:2d;
  fixed-address 192.168.100.253;
}

host altsrv3.den.skv {
  hardware ethernet ae:49:e7:f8:62:2d;
  fixed-address 192.168.100.252;
}

host altsrv4.den.skv {
  hardware ethernet ce:94:fd:b4:54:40;
  fixed-address 192.168.100.251;
}
EOF
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

## перезапуск службы dhcp
```bash
systemctl \
restart \
dhcpd
```
```bash
journalctl -efu dhcpd
```


<details>
<summary>Вывод журнала о регистрации DHCP и DNS НЕ доменной машины</summary>

```log
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: Dynamic and static leases present for 192.168.100.252.
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: Remove host declaration altsrv3.den.skv or remove 192.168.100.252
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: from the dynamic address pool for 192.168.100.0/24
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: Commit: IP: 192.168.100.252 DHCID: ae:49:e7:f8:62:2d Name: altsrv3
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: execute_statement argv[0] = /usr/local/bin/dhcp-dyndns.sh
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: execute_statement argv[1] = add
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: execute_statement argv[2] = 192.168.100.252
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: execute_statement argv[3] = ae:49:e7:f8:62:2d
Apr 03 15:26:49 altsrv2.den.skv dhcpd[4192]: execute_statement argv[4] = altsrv3
Apr 03 15:26:50 altsrv2.den.skv dhcpd[4675]: Record added successfully
Apr 03 15:26:51 altsrv2.den.skv dhcpd[4703]: Record added successfully
Apr 03 15:26:51 altsrv2.den.skv dhcpd[4706]: DHCP-DNS add succeeded
Apr 03 15:26:51 altsrv2.den.skv dhcpd[4717]: Computer 'altsrv3' not found. Exiting.
Apr 03 15:26:51 altsrv2.den.skv dhcpd[4192]: execute: /usr/local/bin/dhcp-dyndns.sh exit status 17408
Apr 03 15:26:51 altsrv2.den.skv dhcpd[4192]: DHCPREQUEST for 192.168.100.252 from ae:49:e7:f8:62:2d via ens19
Apr 03 15:26:51 altsrv2.den.skv dhcpd[4192]: DHCPACK on 192.168.100.252 to ae:49:e7:f8:62:2d via ens19
```

</details>

```bash
# Вывод NS A записи хоста
host altsrv3
```
```log
altsrv3.den.skv has address 192.168.100.252
```
```bash
# Вывод PTR записи хоста
host 192.168.100.252
```
```log
252.100.168.192.in-addr.arpa domain name pointer altsrv3.den.skv.
```

## Настройка переключения failover-DHCP
### Генерация случайного ключа OMAPI
```bash
tsig-keygen -a hmac-md5 omapi_key
```
```json
key "omapi_key" {
        algorithm hmac-md5;
        secret "X1fpFP2WBXkOtsSj8kVwRw==";
};
```
### Замена конфига с Добавлением ключа и failover опций в настройку DHCP сервера
```bash
cat > /etc/dhcp/dhcpd.conf <<'EOF'
authoritative;
ddns-update-style none;

omapi-port 7911;
omapi-key omapi_key;
key "omapi_key" {
        algorithm hmac-md5;
        secret "X1fpFP2WBXkOtsSj8kVwRw==";
};

failover peer "dhcp-failover" {
  primary;
  # Полное DNS-имя основного DHCP-сервера
  address altsrv2.den.skv;
  port 847;
  # Полное DNS-имя имя резервного DHCP-сервера
  peer address altsrv3.den.skv;
  peer port 647;
  max-response-delay 20;
  max-unacked-updates 5;
  mclt 1800;
  split 255;
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

cp  /etc/dhcp/dhcpd.conf{,.working_failover}
```

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

# failover peer "dhcp-failover" {
#   primary;
#   # Полное DNS-имя основного DHCP-сервера
#   address altsrv2.den.skv;
#   port 847;
#   # Полное DNS-имя имя резервного DHCP-сервера
#   peer address altsrv3.den.skv;
#   peer port 647;
#   max-response-delay 20;
#   max-unacked-updates 5;
#   mclt 1800;
#   split 255;
#   load balance max seconds 2;
# }

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
            # failover peer "dhcp-failover";
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

if ! ping -c 2 -W 5 altsrv3.den.skv &>/dev/null; then
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

chmod 755 /usr/local/bin/dhcp-fallback.sh
```
### Создание timer systemd Для отслеживания
```bash
# таймер
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
journalctl -efu dhcpd
```

## Подключение хостов к домену
### Выясняем ip адреса клиентов DHCP
```bash
# Вывод у dhcp сервера об аренде ip на примере у хоста altwks2
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.253 \
'su -c \
"grep -B10 altwks2 \
/var/lib/dhcp/dhcpd/state/dhcpd.leases" \
| grep lease'
```

<details>
<summary>Ищим хост для ввода в домен</summary>

```log
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
Password: 
lease 192.168.100.51 {
Connection to 192.168.100.253 closed
```

</details>

### Подключение к найденому хосту
```bash
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.51 \
"su -"
```

<details>
<summary>подключение с удаленного хоста</summary>

```bash
[shoel@shoellin adm]$ ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.51 \
"su -"
Warning: Permanently added '192.168.100.51' (ED25519) to the list of known hosts.
sysadmin@192.168.100.51's password: 
Password: 
[root@altwks2 ~]# 
```

</details>

### Проверка связи через внешние и локальные DNS
```bash
resolvconf -l
```

<details>
<summary>вывод reolvconf</summary>

```log
# resolv.conf from NetworkManager
# Generated by NetworkManager
search den.skv
nameserver 192.168.100.253
nameserver 192.168.100.252

# resolv.conf from ens19.dhcp
# Generated by dhcpcd from ens19.dhcp
domain den.skv
search den.skv
nameserver 192.168.100.253
nameserver 192.168.100.252
```

</details>



```bash
ping pub.ru -c 2; \
ping den.skv -c 2
```

<details>
<summary>PING</summary>

```log
PING pub.ru (62.122.170.171) 56(84) bytes of data.
64 bytes from 62.122.170.171.serverel.net (62.122.170.171): icmp_seq=1 ttl=53 time=39.8 ms
64 bytes from 62.122.170.171.serverel.net (62.122.170.171): icmp_seq=2 ttl=53 time=40.1 ms

--- pub.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 39.844/39.983/40.122/0.139 ms
PING den.skv (192.168.100.253) 56(84) bytes of data.
64 bytes from 192.168.100.253 (192.168.100.253): icmp_seq=1 ttl=64 time=0.350 ms
64 bytes from 192.168.100.253 (192.168.100.253): icmp_seq=2 ttl=64 time=0.465 ms

--- den.skv ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.350/0.407/0.465/0.057 ms
```

</details>


### Переименовываем имя хоста согласно FQDN имени домена
```bash
hostnamectl set-hostname \
altwks2.den.skv
```
### Обновление системы и Установка пакетов для авторизации машины в Домен
```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get -y install \
task-auth-ad-sssd
```
### проверяем синхронизацию под сервера времени Домена полученные по DHCP
```bash
# чистка конфига от комментариев
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
/etc/chrony.conf
```
```bash
# вывод конфига клиента
cat /etc/chrony.conf
```

<details>
<summary>Конфиг клиента времени chrony</summary>

```log
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
pool 192.168.100.1 iburst
server 192.168.100.253
server 192.168.100.252
```

</details>


### Ввод в домен через командную строку 
```bash
# altwks2 имя вводимого хоста
## smaba_u1 имеет права "Domain Admins"
system-auth write ad \
den.skv \
altwks2 \
den \
'smaba_u1' \
'1qaz@WSX'
```
```log
Using short domain name -- DEN
Joined 'ALTWKS2' to dns domain 'den.skv'
Successfully registered hostname with DNS
```
### Проверка подсоединенного узла
```bash
net ads testjoin
```
```log
Join is OK
```
```bash
ls -lhd /etc/krb5*
```

<details>
<summary>Соджержимое каталога с kerberos</summary>

```log
-rw-r--r-- 1 root root     538 Apr  3 19:51 /etc/krb5.conf
drwxr-xr-x 2 root root    4.0K Apr  3 19:31 /etc/krb5.conf.d
-rw-r----- 1 root _keytab 2.3K Apr  3 19:51 /etc/krb5.keytab
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

```bash
id smaba_u{1..3}
```

<details>
<summary>Вывод информации о пользователях домена id</summary>

```log
uid=1048801103(smaba_u1) gid=1048800513(domain users) groups=1048800513(domain users),1048800512(domain admins),1048800572(denied rodc password replication group),1048801106(вымышленные_герои),100(users),36(vmusers),450(usershares),80(cdwriter),22(cdrom),81(audio),481(video),19(proc),83(radio),471(camera),71(floppy),498(xgrp),499(scanner),14(uucp),476(vboxusers),478(fuse),492(vboxadd),491(vboxsf),101(localadmins),10(wheel)
uid=1048801104(smaba_u2) gid=1048800513(domain users) groups=1048800513(domain users),1048801106(вымышленные_герои),100(users),36(vmusers),450(usershares),80(cdwriter),22(cdrom),81(audio),481(video),19(proc),83(radio),471(camera),71(floppy),498(xgrp),499(scanner),14(uucp),476(vboxusers),478(fuse),492(vboxadd),491(vboxsf)
uid=1048801105(smaba_u3) gid=1048800513(domain users) groups=1048800513(domain users),1048801106(вымышленные_герои),100(users),36(vmusers),450(usershares),80(cdwriter),22(cdrom),81(audio),481(video),19(proc),83(radio),471(camera),71(floppy),498(xgrp),499(scanner),14(uucp),476(vboxusers),478(fuse),492(vboxadd),491(vboxsf
```

</details>

```bash
getent passwd smaba_u{1..3}
```

<details>
<summary>Вывод информации о пользователях домена passwd</summary>

```log
smaba_u1:*:1048801103:1048800513:Василий Иванович Чапаев:/home/DEN.SKV/smaba_u1:/bin/bash
smaba_u2:*:1048801104:1048800513:Моледцев Владимир Александрович:/home/DEN.SKV/smaba_u2:/bin/bash
smaba_u3:*:1048801105:1048800513:Колкин Павел Сергеевич:/home/DEN.SKV/smaba_u3:/bin/bash
```

</details>

```bash
# Проверка работы ролей на хосте введённого в домен
control libnss-role
```
```log
enabled
```
```bash
# Вывод списка ролей хоста
rolelst
```

<details>
<summary>Список ролей после ввода в домен</summary>

```log
users:vmusers,usershares,cdwriter,cdrom,audio,video,proc,radio,camera,floppy,xgrp,scanner,uucp,vboxusers,fuse,vboxadd
domain admins:localadmins
domain users:users
localadmins:wheel,vboxadd,vboxusers
powerusers:remote,vboxadd,vboxusers
vboxadd:vboxsf
```

</details>

## Процедура перезагрузки хоста после ввода в домен
```bash
systemctl reboot
```
## Тестовый вход под учетной записью пользователя smaba_u1
```bash
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
smaba_u1@192.168.100.50
```

<details>
<summary>Лог входа</summary>

```log
smaba_u1@192.168.100.50's password: 
Last login: Fri Apr  3 21:40:54 2026 from 192.168.100.1
```

</details>

```bash
pwd
```
```log
/home/DEN.SKV/smaba_u1
```
```bash
id
```

<details>
<summary>Вывод информации о текущем пользователе</summary>

```log
uid=1048801103(smaba_u1) gid=1048800513(domain users) группы=1048800513(domain users),10(wheel),14(uucp),19(proc),22(cdrom),36(vmusers),71(floppy),80(cdwriter),81(audio),83(radio),100(users),101(localadmins),450(usershares),471(camera),476(vboxusers),478(fuse),481(video),491(vboxsf),492(vboxadd),498(xgrp),499(scanner),1048800512(domain admins),1048800572(denied rodc password replication group),1048801106(вымышленные_герои)
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

git commit -am "[upd2]ДЛЯ ВКР AD SAMBA_INTERNAL DHCP" \
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