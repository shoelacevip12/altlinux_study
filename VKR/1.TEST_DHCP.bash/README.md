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
# Вход на altsrv1(DHCP-server) по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.254 \
"su -"
```
```bash
# Вход на altsrv2 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.253 \
"su -"
```
```bash
# Вход на altsrv3 по новому Ip
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
# `DHCP.BASH`
## Доступ до DHCP сервера ssh
### Проброс имеющегося ключа
```bash
cat ~/.ssh/id_skv_VKR_vpn.pub \
| ssh -J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

<details>
<summary>Успешность проброса</summary>

```bash
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
Warning: Permanently added '192.168.100.11' (ED25519) to the list of known hosts.
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
sysadmin@192.168.100.11's password:
```
</details>

### тестовое соединение до машины
```bash
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
"hostnamectl"
```

<details>
<summary>Успешность тестового соединения</summary>

```bash
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
 Static hostname: altsrv1
       Icon name: computer-vm
         Chassis: vm
      Machine ID: 9c6427a0afb2e5e349a8b9c365780133
         Boot ID: 032cbccdd8354f1faceb91127fe99b14
  Virtualization: kvm
Operating System: ALT Server 10.4 (Mendelevium)
     CPE OS Name: cpe:/o:alt:server:10.4
          Kernel: Linux 5.10.166-std-def-alt1
    Architecture: x86-64
 Hardware Vendor: QEMU
  Hardware Model: Standard PC _i440FX + PIIX, 1996_
Connection to 192.168.100.11 closed.
```
</details>

## Обновление системы
```bash
# Вход на altsrv1
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
"su -"

# Удаление временных конфигов интерфейса
rm -f /etc/net/ifaces/ens19/{options~,ipv4route~}

# обновление системы
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y
```
## Смена статического IP на 192.168.100.254
```bash
# Смен IP адреса для DHCP сервера
sed -i 's/.11/.254/' \
/etc/net/ifaces/ens19/ipv4address

# вывод информации о интерфейсе
cat /etc/net/ifaces/ens19/*

# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown ens19 \
&& ifup ens19 \
&& systemctl restart network
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

hostname -s
```
```
altsrv1
```
```bash
hostname -i
```
```
192.168.100.254
```
```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```bash
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=53 time=13.0 ms
64 bytes from ya.ru (5.255.255.242): icmp_seq=2 ttl=53 time=12.9 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 12.909/12.977/13.045/0.068 ms
```
</details>

## Установка Сервера DHCP
```bash
apt-get update \
&& apt-get install -y \
dhcp-server
```
## Смена имени хоста
```bash
hostnamectl \
set-hostname \
altsrv1.den.skv
```
## Устанавливаем имя NIS-домена
```bash
domainname den.skv
```
## Добавляем домен поиска
```bash
cat >> /etc/net/ifaces/ens19/resolv.conf<<'EOF'
search den.skv
EOF
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

        range dynamic-bootp 192.168.100.50 192.168.100.253;
        default-lease-time 172800;
        max-lease-time 259200;
}

host altsrv2.den.skv {
  hardware ethernet 36:dd:7b:0c:81:2d;
#   binding state active;
  fixed-address 192.168.100.253;
}

host altsrv3.den.skv {
  hardware ethernet ae:49:e7:f8:62:2d;
#   binding state active;
  fixed-address 192.168.100.252;
}

host altsrv4.den.skv {
  hardware ethernet ce:94:fd:b4:54:40;
#   binding state active;
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

```bash
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

```bash
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

### тестовое соединение до машины
```bash
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.12 \
"hostnamectl"
```

<details>
<summary>Успешность тестового соединения</summary>

```bash
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
 Static hostname: altsrv2
       Icon name: computer-vm
         Chassis: vm
      Machine ID: 9c6427a0afb2e5e349a8b9c365780133
         Boot ID: 3d10de1b8a4146f8843338a17368a088
  Virtualization: kvm
Operating System: ALT Server 10.4 (Mendelevium)
     CPE OS Name: cpe:/o:alt:server:10.4
          Kernel: Linux 5.10.166-std-def-alt1
    Architecture: x86-64
 Hardware Vendor: QEMU
  Hardware Model: Standard PC _i440FX + PIIX, 1996_
Connection to 192.168.100.12 closed.
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
rm -f /etc/net/ifaces/ens19/{options~,ipv4route~}
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

## Смена статического IP на dhcp (должен получить `192.168.100.253`)
```bash
# Смена IP статики адреса на DHCP
cat > /etc/net/ifaces/ens19/options <<'EOF'
BOOTPROTO=dhcp
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
CONFIG_IPV6=no
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
ONBOOT=yes
EOF

# Удаление файлов для статической настройки IP Интерфейса
find /etc/net/ifaces/ens19/ \
-mindepth 1 \
-not -path "*options" \
-delete

# вывод информации о интерфейсе
cat /etc/net/ifaces/ens19/*

# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown ens19 \
&& ifup ens19 \
&& systemctl restart network
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
```
altsrv2.den.skv
```
```bash
hostname -i
```
```
192.168.100.253
```
```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```bash
PING ya.ru (77.88.44.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.44.242): icmp_seq=1 ttl=53 time=13.8 ms
64 bytes from ya.ru (77.88.44.242): icmp_seq=2 ttl=53 time=13.9 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 13.781/13.818/13.856/0.037 ms
```
</details>

## обновление системы altsrv2
```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y
```

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

```bash
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
Warning: Permanently added '192.168.100.13' (ED25519) to the list of known hosts.
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
sysadmin@192.168.100.13's password: 
```
</details>

### тестовое соединение до машины
```bash
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.13 \
"hostnamectl"
```

<details>
<summary>Успешность тестового соединения</summary>

```bash
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
 Static hostname: altsrv3
       Icon name: computer-vm
         Chassis: vm
      Machine ID: 9c6427a0afb2e5e349a8b9c365780133
         Boot ID: 4671bb1977044e17832fc191b3f2ae2c
  Virtualization: kvm
Operating System: ALT Server 10.4 (Mendelevium)
     CPE OS Name: cpe:/o:alt:server:10.4
          Kernel: Linux 5.10.166-std-def-alt1
    Architecture: x86-64
 Hardware Vendor: QEMU
  Hardware Model: Standard PC _i440FX + PIIX, 1996_
Connection to 192.168.100.13 closed.
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
rm -f /etc/net/ifaces/ens19/{options~,ipv4route~}
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

## Смена статического IP на dhcp (должен получить `192.168.100.252`)
```bash
# Смена IP статики адреса на DHCP
cat > /etc/net/ifaces/ens19/options <<'EOF'
BOOTPROTO=dhcp
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
CONFIG_IPV6=no
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
ONBOOT=yes
EOF

# Удаление файлов для статической настройки IP Интерфейса
find /etc/net/ifaces/ens19/ \
-mindepth 1 \
-not -path "*options" \
-delete

# вывод информации о интерфейсе
cat /etc/net/ifaces/ens19/*

# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown ens19 \
&& ifup ens19 \
&& systemctl restart network
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
```
altsrv3.den.skv
```
```bash
hostname -i
```
```
192.168.100.252
```
```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```bash
PING ya.ru (77.88.44.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.44.242): icmp_seq=1 ttl=53 time=14.1 ms
64 bytes from ya.ru (77.88.44.242): icmp_seq=2 ttl=53 time=14.1 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 14.051/14.060/14.069/0.009 ms
```
</details>

## обновление системы altsrv3
```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y
```

## Доступ до altsrv4 сервера ssh
### Проброс имеющегося ключа
```bash
cat ~/.ssh/id_skv_VKR_vpn.pub \
| ssh -J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

<details>
<summary>Успешность проброса</summary>

```bash
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
Warning: Permanently added '192.168.100.14' (ED25519) to the list of known hosts.
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
sysadmin@192.168.100.14's password: 
```
</details>

### тестовое соединение до машины
```bash
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
"hostnamectl"
```

<details>
<summary>Успешность тестового соединения</summary>

```bash
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
 Static hostname: altsrv4
       Icon name: computer-vm
         Chassis: vm
      Machine ID: 9c6427a0afb2e5e349a8b9c365780133
         Boot ID: 12f8d2316737419493c47e93aa417b15
  Virtualization: kvm
Operating System: ALT Server 10.4 (Mendelevium)
     CPE OS Name: cpe:/o:alt:server:10.4
          Kernel: Linux 5.10.166-std-def-alt1
    Architecture: x86-64
 Hardware Vendor: QEMU
  Hardware Model: Standard PC _i440FX + PIIX, 1996_
Connection to 192.168.100.14 closed.
```
</details>

## Смена имени хоста
```bash
# Вход на altsrv4
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
"su -"

# Удаление временных конфигов интерфейса
rm -f /etc/net/ifaces/ens19/{options~,ipv4route~}
```
```bash
hostnamectl \
set-hostname \
altsrv4.den.skv
```
## Устанавливаем имя NIS-домена
```bash
domainname den.skv
```

## Смена статического IP на dhcp (должен получить `192.168.100.251`)
```bash
# Смена IP статики адреса на DHCP
cat > /etc/net/ifaces/ens19/options <<'EOF'
BOOTPROTO=dhcp
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
CONFIG_IPV6=no
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
ONBOOT=yes
EOF

# Удаление файлов для статической настройки IP Интерфейса
find /etc/net/ifaces/ens19/ \
-mindepth 1 \
-not -path "*options" \
-delete

# вывод информации о интерфейсе
cat /etc/net/ifaces/ens19/*

# Выключение и включения интерфейса  с сеть для сброса и перезапуск службы для запуска мостового
ifdown ens19 \
&& ifup ens19 \
&& systemctl restart network
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
```
altsrv4.den.skv
```
```bash
hostname -i
```
```
192.168.100.251
```
```bash
ping ya.ru -c2
```

<details>
<summary>Проверка выхода в интернет</summary>

```bash
PING ya.ru (77.88.44.242) 56(84) bytes of data.
64 bytes from ya.ru (77.88.44.242): icmp_seq=1 ttl=53 time=13.9 ms
64 bytes from ya.ru (77.88.44.242): icmp_seq=2 ttl=53 time=13.8 ms

--- ya.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 13.849/13.864/13.879/0.015 ms
```
</details>

## обновление системы altsrv4
```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y
```

## Смен ip со статики на DHCP altwks2
```bash
# Вход на altwks2
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.2 \
"su -"
```
## Смена на dhcp основных настроек
```bash
cat > /etc/net/ifaces/ens19/options <<'EOF'
BOOTPROTO=dhcp
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
CONFIG_IPV6=no
SYSTEMD_CONTROLLED=no
ONBOOT=yes
NM_CONTROLLED=yes
DISABLED=yes
EOF
```
```bash
# Удаление файлов для статической настройки IP Интерфейса
find /etc/net/ifaces/ens19/ \
-mindepth 1 \
-not -path "*options" \
-delete

# вывод информации о интерфейсе
cat /etc/net/ifaces/ens19/*

# Перезагрузка хоста
systemctl reboot
```

Последовательность Для принудительного закрытия SSH-сессии без ожидания таймаута
1. **Enter**, чтобы убедиться, что курсор не реагирует.
2. Нажать символ **`~`** (тильда).
3. Затем нажмать **`.`** (точка).

## Вывод у dhcp сервера об аренде ip у хоста altwks2
```bash
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.254 \
'su -c "grep -B10 altwks2 /var/lib/dhcp/dhcpd/state/dhcpd.leases"'
```

<details>
<summary>Вывод информации об аренде ip клиенту</summary>

```bash
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
** WARNING: connection is not using a post-quantum key exchange algorithm.
** This session may be vulnerable to "store now, decrypt later" attacks.
** The server may need to be upgraded. See https://openssh.com/pq.html
Password: 

lease 192.168.100.50 {
  starts 4 2026/04/02 17:13:39;
  ends 6 2026/04/04 17:13:39;
  cltt 4 2026/04/02 17:13:39;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 6a:36:90:85:f6:66;
  uid "\001j6\220\205\366f";
  client-hostname "altwks2";
Connection to 192.168.100.254 closed.
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

git commit -am "ДЛЯ ВКР ручная настройка базового DHCP" \
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